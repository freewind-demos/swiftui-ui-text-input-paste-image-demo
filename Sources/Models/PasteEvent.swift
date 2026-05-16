import Foundation
import AppKit

enum PasteEvent {
    case inlineImage(NSImage)
    case fallbackImage(NSImage)
    case noImage
}
