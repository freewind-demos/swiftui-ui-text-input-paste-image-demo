import Foundation
import Observation
import AppKit

@Observable
@MainActor
final class PasteImageEditorStore {
    var document = NSAttributedString(string: "")
    var fallbackImage: NSImage?
    var statusText = "点输入框后按 Cmd+V，或点按钮试试把剪贴板图片贴进去。"
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

    func showFallbackImage(_ image: NSImage) {
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
