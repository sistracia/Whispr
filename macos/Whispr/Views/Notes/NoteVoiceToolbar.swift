import SwiftUI
import ScreenCaptureKit

enum AppsAvailable: String {
    case none = "<None>"
}

struct NoteVoiceToolbar: ToolbarContent {
    @ObservedObject var screenRecorder: ScreenRecorder
    @ObservedObject var micRecorder: MicRecorder
    
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
            Menu {
                Toggle(
                    "Record Microphone",
                    systemImage: "record.circle",
                    isOn: $recordMic
                )
                .disabled(micRecorder.captureDevice == nil)
                .onChange(of: recordMic) { _, isOn in
                    Task {
                        if isOn {
                            await micRecorder.startStream()
                        } else {
                            micRecorder.stopStreaming()
                        }
                    }
                }
                
                Picker("Select Microphone", selection: $micRecorder.captureDevice) {
                    ForEach(micRecorder.captureDevices, id: \.self) { captureDevice in
                        Text(captureDevice.localizedName)
                            .tag(captureDevice)
                    }
                }
                .pickerStyle(.inline)
                .disabled(micRecorder.state == .streaming)
            } label: {
                Label("Microphone", systemImage: micRecorder.state == .stopped ? "microphone"  : "microphone.slash" )
            }
        }
    }
}
