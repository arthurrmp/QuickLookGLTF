import Cocoa
import QuickLookUI
import WebKit

private let customScheme = "glbres"

class ResourceSchemeHandler: NSObject, WKURLSchemeHandler {
    let bundle: Bundle
    var modelFileURL: URL?
    var cachedResources: [String: Data] = [:]

    init(bundle: Bundle) {
        self.bundle = bundle
    }

    /// Pre-load external resources referenced by a .gltf file.
    /// Must be called from preparePreviewOfFile where sandbox grants file access.
    func preloadGLTFResources(for gltfURL: URL) {
        guard let jsonData = try? Data(contentsOf: gltfURL),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else { return }

        let dir = gltfURL.deletingLastPathComponent()
        var uris: [String] = []

        if let buffers = json["buffers"] as? [[String: Any]] {
            for buffer in buffers {
                if let uri = buffer["uri"] as? String, !uri.hasPrefix("data:") {
                    uris.append(uri)
                }
            }
        }
        if let images = json["images"] as? [[String: Any]] {
            for image in images {
                if let uri = image["uri"] as? String, !uri.hasPrefix("data:") {
                    uris.append(uri)
                }
            }
        }

        for uri in uris {
            let fileURL = dir.appendingPathComponent(uri)
            if let data = try? Data(contentsOf: fileURL) {
                cachedResources[uri] = data
            }
        }
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(URLError(.badURL))
            return
        }

        let filename = url.lastPathComponent
        let data: Data
        let mimeType: String

        let ext = url.pathExtension

        if (filename == "model.glb" || filename == "model.gltf"), let modelURL = modelFileURL {
            guard let fileData = try? Data(contentsOf: modelURL) else {
                urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
                return
            }
            data = fileData
            mimeType = ext == "gltf" ? "model/gltf+json" : "model/gltf-binary"
        } else {
            let name = url.deletingPathExtension().lastPathComponent

            if let fileURL = bundle.url(forResource: name, withExtension: ext),
               let fileData = try? Data(contentsOf: fileURL) {
                data = fileData
            } else if let cached = cachedResources[filename] {
                data = cached
            } else {
                urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
                return
            }

            switch ext {
            case "html": mimeType = "text/html"
            case "js": mimeType = "text/javascript"
            case "wasm": mimeType = "application/wasm"
            case "png": mimeType = "image/png"
            case "jpg", "jpeg": mimeType = "image/jpeg"
            case "bin": mimeType = "application/octet-stream"
            default: mimeType = "application/octet-stream"
            }
        }

        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: [
                "Content-Type": mimeType,
                "Content-Length": "\(data.count)"
            ]
        )!
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}
}

class PreviewViewController: NSViewController, QLPreviewingController, WKNavigationDelegate {
    private var webView: WKWebView!
    private var schemeHandler: ResourceSchemeHandler!
    private var previewHandler: ((Error?) -> Void)?

    override func loadView() {
        let config = WKWebViewConfiguration()
        schemeHandler = ResourceSchemeHandler(bundle: Bundle(for: type(of: self)))
        config.setURLSchemeHandler(schemeHandler, forURLScheme: customScheme)
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        view = webView
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        schemeHandler.modelFileURL = url

        if url.pathExtension.lowercased() == "gltf" {
            schemeHandler.preloadGLTFResources(for: url)
        }

        previewHandler = handler
        webView.load(URLRequest(url: URL(string: "\(customScheme)://resources/viewer.html")!))
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let ext = schemeHandler.modelFileURL?.pathExtension.lowercased() == "gltf" ? "gltf" : "glb"
        webView.evaluateJavaScript("loadModel('\(customScheme)://resources/model.\(ext)')") { [weak self] _, error in
            self?.previewHandler?(error)
            self?.previewHandler = nil
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        previewHandler?(error)
        previewHandler = nil
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        previewHandler?(error)
        previewHandler = nil
    }
}
