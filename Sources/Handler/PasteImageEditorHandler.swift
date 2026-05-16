import Foundation

@MainActor
final class PasteImageEditorHandler {
    private let store: PasteImageEditorStore

    init(store: PasteImageEditorStore) {
        self.store = store
    }

    func updateDocument(_ value: NSAttributedString) {
        store.replaceDocument(value)
    }

    func requestPasteFromClipboard() {
        store.bumpPasteRequest()
    }

    func handlePasteEvent(_ event: PasteEvent) {
        switch event {
        case .inlineImage:
            store.showInlineImagePasted()
        case let .fallbackImage(image):
            store.showFallbackImage(image)
        case .noImage:
            store.showNoImage()
        }
    }

    func clearAll() {
        store.clearAll()
    }
}
