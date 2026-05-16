import SwiftUI

@main
struct swiftui_ui_text_input_paste_image_demoApp: App {
    @State private var feature = PasteImageEditorFeature()

    var body: some Scene {
        WindowGroup {
            ContentView(feature: feature)
        }
    }
}
