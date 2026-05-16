import SwiftUI

struct ContentView: View {
    let feature: PasteImageEditorFeature

    var body: some View {
        @Bindable var feature = feature

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("输入框贴图测试")
                        .font(.title.bold())

                    Text("点输入框后按 `Cmd+V`，或点下面按钮触发。能 inline 就留在输入框；不行就回退到上方预览。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let fallbackImage = feature.fallbackImage {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("回退预览")
                                .font(.headline)

                            Image(nsImage: fallbackImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 120, maxHeight: 240)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }

                    PasteImageTextEditor(
                        attributedText: feature.document,
                        pasteRequestID: feature.pasteRequestID,
                        onTextChange: feature.updateDocument,
                        onPasteEvent: feature.handlePasteEvent
                    )
                    .frame(minHeight: 260)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                    )

                    Text(feature.statusText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        Button("从剪贴板贴图") {
                            feature.requestPasteFromClipboard()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("清空") {
                            feature.clearAll()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Paste Image Demo")
        }
    }
}

#Preview {
    ContentView(feature: PasteImageEditorFeature())
}
