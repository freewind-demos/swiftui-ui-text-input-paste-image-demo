import UIKit

protocol ClipboardImageReading {
    func firstImage() -> UIImage?
}

struct ClipboardImageApi: ClipboardImageReading {
    func firstImage() -> UIImage? {
        UIPasteboard.general.image
    }
}
