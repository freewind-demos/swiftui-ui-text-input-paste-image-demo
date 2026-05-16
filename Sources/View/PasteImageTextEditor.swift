import SwiftUI
import AppKit

struct PasteImageTextEditor: NSViewRepresentable {
    let attributedText: NSAttributedString
    let pasteRequestID: Int
    let onTextChange: (NSAttributedString) -> Void
    let onPasteEvent: (PasteEvent) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onTextChange: onTextChange)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false

        let textView = PasteImageTextView(clipboardApi: ClipboardImageApi())
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.drawsBackground = true
        textView.backgroundColor = .textBackgroundColor
        textView.font = .systemFont(ofSize: NSFont.systemFontSize)
        textView.textContainerInset = NSSize(width: 16, height: 18)
        textView.isRichText = true
        textView.importsGraphics = false
        textView.onPasteEvent = onPasteEvent
        textView.delegate = context.coordinator
        context.coordinator.textView = textView

        if attributedText.length == 0 {
            context.coordinator.showPlaceholder(in: textView)
        } else {
            textView.textStorage?.setAttributedString(attributedText)
            textView.textColor = .labelColor
        }

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView else {
            return
        }

        textView.onPasteEvent = onPasteEvent
        context.coordinator.onTextChange = onTextChange

        if pasteRequestID != context.coordinator.lastPasteRequestID {
            context.coordinator.lastPasteRequestID = pasteRequestID
            if context.coordinator.isShowingPlaceholder {
                context.coordinator.clearPlaceholder(in: textView)
            }
            textView.pasteClipboardImageOrFallback()
        }

        if attributedText.length == 0, !context.coordinator.isEditing {
            if !context.coordinator.isShowingPlaceholder {
                context.coordinator.showPlaceholder(in: textView)
            }
            return
        }

        if context.coordinator.isShowingPlaceholder {
            context.coordinator.clearPlaceholder(in: textView)
        }

        let currentText = textView.attributedString()
        if !currentText.isEqual(to: attributedText) {
            textView.textStorage?.setAttributedString(attributedText)
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        weak var textView: PasteImageTextView?
        var onTextChange: (NSAttributedString) -> Void
        var lastPasteRequestID = 0
        var isShowingPlaceholder = false
        var isEditing = false

        init(onTextChange: @escaping (NSAttributedString) -> Void) {
            self.onTextChange = onTextChange
        }

        func textDidBeginEditing(_ notification: Notification) {
            isEditing = true
            guard
                isShowingPlaceholder,
                let textView = notification.object as? NSTextView
            else {
                return
            }
            clearPlaceholder(in: textView)
        }

        func textDidEndEditing(_ notification: Notification) {
            isEditing = false
        }

        func textDidChange(_ notification: Notification) {
            guard
                !isShowingPlaceholder,
                let textView = notification.object as? NSTextView
            else {
                return
            }
            onTextChange(textView.attributedString())
        }

        func showPlaceholder(in textView: NSTextView) {
            isShowingPlaceholder = true
            textView.string = "在这里输入文字，再试着粘贴图片。"
            textView.textColor = .placeholderTextColor
        }

        func clearPlaceholder(in textView: NSTextView) {
            isShowingPlaceholder = false
            textView.string = ""
            textView.textColor = .labelColor
        }
    }
}

final class PasteImageTextView: NSTextView {
    private let clipboardApi: ClipboardImageReading
    var onPasteEvent: ((PasteEvent) -> Void)?

    init(clipboardApi: ClipboardImageReading) {
        self.clipboardApi = clipboardApi
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(containerSize: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        super.init(frame: .zero, textContainer: textContainer)
        allowsUndo = true
        isEditable = true
        isSelectable = true
        allowsImageEditing = true
        usesAdaptiveColorMappingForDarkAppearance = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        if item.action == #selector(paste(_:)), clipboardApi.firstImage() != nil {
            return true
        }
        return super.validateUserInterfaceItem(item)
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

    private func insertInlineImage(_ image: NSImage) -> Bool {
        let containerWidth = textContainer?.containerSize.width ?? bounds.width
        let maxWidth = max(containerWidth - (textContainerInset.width * 2), 120)
        let fittedSize = image.size.fitted(maxWidth: maxWidth)
        guard fittedSize.width > 0, fittedSize.height > 0 else {
            return false
        }

        let attachment = NSTextAttachment()
        attachment.attachmentCell = FixedSizeAttachmentCell(image: image, size: fittedSize)

        let selectedRange = selectedRange()
        let attachmentText = NSMutableAttributedString(string: "\n")
        attachmentText.append(NSAttributedString(attachment: attachment))
        attachmentText.append(NSAttributedString(string: "\n"))

        textStorage?.replaceCharacters(in: selectedRange, with: attachmentText)
        setSelectedRange(NSRange(location: min(selectedRange.location + attachmentText.length, string.count), length: 0))
        didChangeText()
        return true
    }
}

final class FixedSizeAttachmentCell: NSTextAttachmentCell {
    private let size: NSSize

    init(image: NSImage, size: NSSize) {
        self.size = size
        super.init(imageCell: image)
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func cellSize() -> NSSize {
        size
    }

    override func cellFrame(
        for textContainer: NSTextContainer?,
        proposedLineFragment lineFrag: NSRect,
        glyphPosition position: NSPoint,
        characterIndex charIndex: Int
    ) -> NSRect {
        NSRect(origin: CGPoint(x: 0, y: 0), size: size)
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
