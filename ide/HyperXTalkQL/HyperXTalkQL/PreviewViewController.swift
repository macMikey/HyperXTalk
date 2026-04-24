// PreviewViewController.swift
// HyperXTalkQL — Quick Look preview extension for .hyperxtalk stack files.
//
// When a .hyperxtalk file is selected in Finder, macOS calls this extension.
// We read the PNG snapshot stored in the "com.hyperxtalk.qlpreview" extended
// attribute (written by the HyperXTalk engine on each save) and display it.
// If the attribute is absent (e.g. an older stack that was never re-saved),
// we show a plain placeholder instead.

import Cocoa
import Quartz

class PreviewViewController: NSViewController, QLPreviewingController {

    // No storyboard — create the view programmatically.
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 512, height: 512))
    }

    private static let xattrName = "com.hyperxtalk.qlpreview"

    // MARK: - QLPreviewingController

    func preparePreviewOfFile(at url: URL,
                              completionHandler handler: @escaping (Error?) -> Void) {
        if let image = loadPreviewImage(from: url) {
            showImage(image)
        } else {
            showPlaceholder()
        }
        handler(nil)
    }

    // MARK: - Image loading

    private func loadPreviewImage(from url: URL) -> NSImage? {
        // Read the extended attribute written by the engine.
        let path = url.path
        let xattr = Self.xattrName

        // Query the xattr size first.
        let size = getxattr(path, xattr, nil, 0, 0, 0)
        guard size > 0 else { return nil }

        var buffer = [UInt8](repeating: 0, count: size)
        let read = getxattr(path, xattr, &buffer, size, 0, 0)
        guard read == size else { return nil }

        let data = Data(bytes: buffer, count: size)
        return NSImage(data: data)
    }

    // MARK: - View setup

    private func showImage(_ image: NSImage) {
        let imageView = NSImageView(frame: view.bounds)
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.autoresizingMask = [.width, .height]
        view.addSubview(imageView)
    }

    private func showPlaceholder() {
        // Stack exists but has no embedded preview (saved before this feature,
        // or saved headlessly).  Show the file icon as a fallback.
        let iconView = NSImageView(frame: view.bounds)
        iconView.image = NSWorkspace.shared.icon(forFileType: "hyperxtalk")
        iconView.imageScaling = .scaleProportionallyDown
        iconView.autoresizingMask = [.width, .height]
        view.addSubview(iconView)
    }
}
