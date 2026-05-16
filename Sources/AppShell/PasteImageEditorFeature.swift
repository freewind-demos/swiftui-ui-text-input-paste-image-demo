import Foundation
import Observation
import UIKit

@Observable
@MainActor
final class PasteImageEditorFeature {
    let store: PasteImageEditorStore
    private let handler: PasteImageEditorHandler

    init(store: PasteImageEditorStore = PasteImageEditorStore()) {
        self.store = store
        self.handler = PasteImageEditorHandler(store: store)
    }

    var document: NSAttributedString {
        store.document
    }

    var fallbackImage: UIImage? {
        store.fallbackImage
    }

    var statusText: String {
        store.statusText
    }

    var pasteRequestID: Int {
        store.pasteRequestID
    }

    func updateDocument(_ value: NSAttributedString) {
        handler.updateDocument(value)
    }

    func requestPasteFromClipboard() {
        handler.requestPasteFromClipboard()
    }

    func handlePasteEvent(_ event: PasteEvent) {
        handler.handlePasteEvent(event)
    }

    func clearAll() {
        handler.clearAll()
    }
}
