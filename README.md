# QuickLookGLTF

A macOS Quick Look extension for previewing `.glb` and `.gltf` 3D model files directly in Finder, Spotlight, and anywhere else Quick Look is used.

Built with [Three.js](https://threejs.org) running inside a WKWebView.

## Features

- Preview `.glb` and `.gltf` files with Quick Look (press Space in Finder)
- Orbit, zoom, and pan with mouse/trackpad
- Plays the first animation if the model has one
- Supports Draco, KTX2, and Meshopt compressed models
- Auto-frames the camera to fit the model

## Requirements

- macOS 13.0+
- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (to generate the Xcode project)
- Node.js (to build the JS bundle)

## Build

```bash
# Generate the Xcode project
xcodegen

# Install JS dependencies and bundle Three.js
npm install
npm run build

# Open in Xcode and build
open QuickLookGLTF.xcodeproj
```

## Install

After building in Xcode, the Quick Look extension is embedded inside `QuickLookGLTF.app`. To activate it:

1. Build and run in Xcode
2. Open System Settings > Extensions > Quick Look
3. Enable **GLTF Preview**

Then press Space on any `.glb` or `.gltf` file in Finder.

## Updating Three.js

```bash
npm update three
npm run build
```

## Project Structure

```
src/entry.js                    Three.js viewer (source)
GLTFPreview/                    Quick Look extension target
  PreviewViewController.swift   WKWebView + custom URL scheme handler
  viewer.html                   Minimal HTML shell
  bundle.js                     Built JS bundle (generated)
  *.wasm, *.js                  Runtime decoder files (copied from npm)
QuickLookGLTF/                  Host app target
  AppDelegate.swift
project.yml                     XcodeGen project definition
```

## License

MIT

## Acknowledgments

- [Three.js](https://threejs.org) — MIT License, Copyright 2010-2026 three.js authors
