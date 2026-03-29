import Cocoa

private let isSequoiaOrLater = ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 15

class AppDelegate: NSObject, NSApplicationDelegate {
    private lazy var window: NSWindow = {
        let textX: CGFloat = 90
        let textW: CGFloat = 300
        let winW: CGFloat = 420
        let winH: CGFloat = 290

        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: winW, height: winH),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        w.title = "QuickLookGLTF"
        w.isReleasedWhenClosed = false
        w.center()

        let view = NSView(frame: w.contentView!.bounds)
        view.autoresizingMask = [.width, .height]

        // Title
        let title = NSTextField(labelWithString: "QuickLookGLTF is installed")
        title.font = .systemFont(ofSize: 18, weight: .semibold)
        title.frame = NSRect(x: textX, y: 232, width: textW, height: 24)
        view.addSubview(title)

        // Usage
        let usage = NSTextField(wrappingLabelWithString: "Press Space on any .glb or .gltf file in Finder to preview it.")
        usage.font = .systemFont(ofSize: 13)
        usage.textColor = .secondaryLabelColor
        usage.frame = NSRect(x: textX, y: 196, width: textW, height: 32)
        view.addSubview(usage)

        // Troubleshooting label
        let troubleLabel = NSTextField(labelWithString: "If it's not working, on System Settings:")
        troubleLabel.font = .systemFont(ofSize: 11)
        troubleLabel.textColor = .tertiaryLabelColor
        troubleLabel.frame = NSRect(x: textX, y: 168, width: textW, height: 14)
        view.addSubview(troubleLabel)

        // Steps
        let steps = isSequoiaOrLater
            ? "→ General\n→ Login Items & Extensions\n→ Scroll to Extensions\n→ Click ⓘ next to QuickLookGLTF\n→ Enable Quick Look"
            : "→ Privacy & Security\n→ Extensions\n→ Quick Look\n→ Enable QuickLookGLTF"
        let body = NSTextField(wrappingLabelWithString: steps)
        body.font = .systemFont(ofSize: 13)
        body.textColor = .secondaryLabelColor
        body.frame = NSRect(x: textX, y: 62, width: textW, height: 100)
        view.addSubview(body)

        // Icon centered vertically with the text content
        let icon = NSImageView(frame: NSRect(x: 24, y: 140, width: 48, height: 48))
        icon.image = NSImage(systemSymbolName: "cube.transparent", accessibilityDescription: nil)
        icon.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 32, weight: .light)
        icon.contentTintColor = .tertiaryLabelColor
        view.addSubview(icon)

        // Button
        let button = NSButton(title: "Open Settings", target: self, action: #selector(openSettings))
        button.bezelStyle = .rounded
        button.frame = NSRect(x: textX, y: 20, width: 160, height: 28)
        view.addSubview(button)

        w.contentView = view
        return w
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            window.makeKeyAndOrderFront(nil)
        }
        return true
    }

    @objc private func openSettings() {
        let id = isSequoiaOrLater
            ? "com.apple.LoginItems-Settings.extension"
            : "com.apple.ExtensionsPreferences"
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:\(id)")!)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }
}
