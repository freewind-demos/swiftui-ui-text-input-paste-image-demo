import Foundation
import UIKit

enum PasteEvent {
    case inlineImage(UIImage)
    case fallbackImage(UIImage)
    case noImage
}
