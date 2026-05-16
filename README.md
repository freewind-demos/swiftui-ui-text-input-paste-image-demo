# swiftui-ui-text-input-paste-image-demo

macOS SwiftUI demo。目标：验证文本输入框内粘贴图片时，优先走 inline image；失败时回退到上方预览。

## 功能

- `Cmd+V` 直接向输入框粘贴剪贴板图片
- 点击“从剪贴板贴图”按钮，触发同一套贴图流程
- inline 成功：图片作为 `NSTextAttachment` 插入 `NSTextView`
- inline 失败：图片显示到上方 fallback 预览区
- 剪贴板无图：底部状态文案提示

## 分层

- `Sources/AppShell/PasteImageEditorFeature.swift`
  - 对 View 暴露薄 facade
- `Sources/Handler/PasteImageEditorHandler.swift`
  - 编排贴图事件、状态更新
- `Sources/Store/PasteImageEditorStore.swift`
  - 持有 `document`、`fallbackImage`、`statusText`、`pasteRequestID`
- `Sources/SystemApi/ClipboardImageApi.swift`
  - 读取剪贴板首张图片
- `Sources/View/PasteImageTextEditor.swift`
  - `NSViewRepresentable` 包装 `NSTextView`
  - 拦截 `paste(_:)`
  - 插入 inline image / 发出 fallback event
- `Sources/View/ContentView.swift`
  - 页面布局、按钮、状态展示

## 关键流

1. 聚焦输入框，按 `Cmd+V`
2. `PasteImageTextView.paste(_:)` 先尝试 `pasteClipboardImageOrFallback()`
3. 若剪贴板有图：
   - `insertInlineImage(_:)` 成功 → store 更新为“图片已直接贴进输入框”
   - `insertInlineImage(_:)` 失败 → store 挂 `fallbackImage`
4. 若剪贴板无图：
   - 回退系统默认粘贴
   - 同时状态区提示“剪贴板里没读到图片”

按钮“从剪贴板贴图”走另一入口：`Feature.requestPasteFromClipboard()` → `Store.bumpPasteRequest()` → `updateNSView` 检测到 `pasteRequestID` 变化后触发同一套贴图逻辑。

## 运行

要求：

- macOS 14+
- Xcode 16+
- Swift 6

编译：

```bash
./swift-compile-build.fish
```

打开工程：

```bash
open swiftui-ui-text-input-paste-image-demo.xcodeproj
```

## 用途

适合验证这些问题：

- SwiftUI `TextEditor` 不够用时，如何桥接 `NSTextView`
- 如何接管 macOS 粘贴动作
- 如何把图片按固定宽度缩放后插入富文本
- 如何给 inline 粘贴失败提供可见 fallback
