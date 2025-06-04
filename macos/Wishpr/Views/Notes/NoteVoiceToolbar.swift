import SwiftUI
import ScreenCaptureKit

enum AppsAvailable: String {
    case none = "<None>"
}

struct NoteVoiceToolbar: ToolbarContent {
    @ObservedObject var screenRecorder: ScreenRecorder
    @Binding var recordApp: String
    @Binding var recordDesktop: Bool
    @Binding var recordMic: Bool
    
    var placement: ToolbarItemPlacement
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: placement) {
            Menu {
                Picker("Record App", selection: $recordApp) {
                    Text(AppsAvailable.none.rawValue).tag(AppsAvailable.none)
                    ForEach(screenRecorder.availableWindows, id: \.self) { window in
                        Text(window.displayName)
                            .tag(SCWindow?.some(window))
                    }
                }
                .pickerStyle(.inline)
            } label: {
                Label("App Recorder", systemImage: "inset.filled.rectangle.badge.record")
            }
            Toggle(
                "Record Desktop",
                systemImage: "menubar.dock.rectangle.badge.record",
                isOn: $recordDesktop
            )
            Toggle(
                "Record Mic",
                systemImage: "record.circle",
                isOn: $recordMic
            )
        }
    }
}
