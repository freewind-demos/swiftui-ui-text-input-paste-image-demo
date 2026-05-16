import Foundation
import Observation
import UIKit

@Observable
@MainActor
final class PasteImageEditorStore {
    var document = NSAttributedString(string: "")
    var fallbackImage: UIImage?
    var statusText = "长按输入框或按按钮，试试把剪贴板图片贴进去。"
    var pasteRequestID = 0

    func replaceDocument(_ value: NSAttributedString) {
        document = value
    }

    func bumpPasteRequest() {
        pasteRequestID &+= 1
    }

    func showInlineImagePasted() {
        fallbackImage = nil
        statusText = "图片已直接贴进输入框。"
    }

    func showFallbackImage(_ image: UIImage) {
        fallbackImage = image
        statusText = "当前输入框没走成 inline，图片已回退到上方预览。"
    }

    func showNoImage() {
        statusText = "剪贴板里没读到图片。"
    }

    func clearAll() {
        document = NSAttributedString(string: "")
        fallbackImage = nil
        statusText = "已清空。继续贴图测试。"
    }
}
