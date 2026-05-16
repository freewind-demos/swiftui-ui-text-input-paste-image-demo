import SwiftUI
import UIKit

struct PasteImageTextEditor: UIViewRepresentable {
    let attributedText: NSAttributedString
    let pasteRequestID: Int
    let onTextChange: (NSAttributedString) -> Void
    let onPasteEvent: (PasteEvent) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onTextChange: onTextChange)
    }

    func makeUIView(context: Context) -> PasteImageTextView {
        let textView = PasteImageTextView(clipboardApi: ClipboardImageApi())
        textView.backgroundColor = .secondarySystemBackground
        textView.layer.cornerRadius = 20
        textView.font = .preferredFont(forTextStyle: .body)
        textView.textContainerInset = UIEdgeInsets(top: 18, left: 16, bottom: 18, right: 16)
        textView.onPasteEvent = onPasteEvent
        textView.delegate = context.coordinator
        textView.attributedText = attributedText
        if attributedText.length == 0 {
            textView.text = "在这里输入文字，再试着粘贴图片。"
            textView.textColor = .placeholderText
            context.coordinator.isShowingPlaceholder = true
        }
        return textView
    }

    func updateUIView(_ uiView: PasteImageTextView, context: Context) {
        uiView.onPasteEvent = onPasteEvent
        context.coordinator.onTextChange = onTextChange

        if pasteRequestID != context.coordinator.lastPasteRequestID {
            context.coordinator.lastPasteRequestID = pasteRequestID
            if context.coordinator.isShowingPlaceholder {
                context.coordinator.isShowingPlaceholder = false
                uiView.text = ""
                uiView.textColor = .label
            }
            uiView.pasteClipboardImageOrFallback()
        }

        if attributedText.length == 0, !uiView.isFirstResponder {
            if !context.coordinator.isShowingPlaceholder {
                context.coordinator.isShowingPlaceholder = true
                uiView.text = "在这里输入文字，再试着粘贴图片。"
                uiView.textColor = .placeholderText
            }
            return
        }

        if context.coordinator.isShowingPlaceholder {
            context.coordinator.isShowingPlaceholder = false
            uiView.textColor = .label
        }

        if !uiView.attributedText.isEqual(to: attributedText) {
            uiView.attributedText = attributedText
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var onTextChange: (NSAttributedString) -> Void
        var lastPasteRequestID = 0
        var isShowingPlaceholder = false

        init(onTextChange: @escaping (NSAttributedString) -> Void) {
            self.onTextChange = onTextChange
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            guard isShowingPlaceholder else { return }
            isShowingPlaceholder = false
            textView.text = ""
            textView.textColor = .label
        }

        func textViewDidChange(_ textView: UITextView) {
            onTextChange(textView.attributedText)
        }
    }
}

final class PasteImageTextView: UITextView {
    private let clipboardApi: ClipboardImageReading
    var onPasteEvent: ((PasteEvent) -> Void)?

    init(clipboardApi: ClipboardImageReading) {
        self.clipboardApi = clipboardApi
        super.init(frame: .zero, textContainer: nil)
        allowsEditingTextAttributes = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(paste(_:)), clipboardApi.firstImage() != nil {
            return true
        }
        return super.canPerformAction(action, withSender: sender)
    }

    override func paste(_ sender: Any?) {
        if pasteClipboardImageOrFallback() {
            return
        }
        super.paste(sender)
    }

    @discardableResult
    func pasteClipboardImageOrFallback() -> Bool {
        guard let image = clipboardApi.firstImage() else {
            onPasteEvent?(.noImage)
            return false
        }

        guard insertInlineImage(image) else {
            onPasteEvent?(.fallbackImage(image))
            return true
        }

        onPasteEvent?(.inlineImage(image))
        return true
    }

    private func insertInlineImage(_ image: UIImage) -> Bool {
        let maxWidth = max(textContainer.size.width - textContainerInset.left - textContainerInset.right, 120)
        let fittedSize = image.size.fitted(maxWidth: maxWidth)
        guard fittedSize.width > 0, fittedSize.height > 0 else {
            return false
        }

        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = CGRect(origin: CGPoint(x: 0, y: 0), size: fittedSize)

        let mutable = NSMutableAttributedString(attributedString: attributedText)
        let attachmentText = NSMutableAttributedString(string: "\n")
        attachmentText.append(NSAttributedString(attachment: attachment))
        attachmentText.append(NSAttributedString(string: "\n"))
        mutable.replaceCharacters(in: selectedRange, with: attachmentText)

        attributedText = mutable
        selectedRange = NSRange(location: min(selectedRange.location + attachmentText.length, mutable.length), length: 0)
        delegate?.textViewDidChange?(self)
        return true
    }
}

private extension CGSize {
    func fitted(maxWidth: CGFloat) -> CGSize {
        guard width > 0, height > 0 else {
            return .zero
        }

        if width <= maxWidth {
            return self
        }

        let ratio = maxWidth / width
        return CGSize(width: maxWidth, height: height * ratio)
    }
}
