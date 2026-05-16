import AppKit

protocol ClipboardImageReading {
    func firstImage() -> NSImage?
}

struct ClipboardImageApi: ClipboardImageReading {
    func firstImage() -> NSImage? {
        let classes: [AnyClass] = [NSImage.self]
        let items = NSPasteboard.general.readObjects(forClasses: classes, options: nil)
        return items?.first as? NSImage
    }
}
