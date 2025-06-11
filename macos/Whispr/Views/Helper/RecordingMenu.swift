import Foundation
import SwiftUI

struct RecordingMenu<SelectionValue:Hashable, Content:View>: View {
    let recordToggleLabel: String
    let disableRecord: Bool
    let pickerSourceLabel: String
    let selection: Binding<SelectionValue>
    let menuLabel: String
    let isRecording: Bool
    let recordingIcon: String
    let notRecordingIcon: String
    let isOn: Binding<Bool>
    @ViewBuilder let content: () -> Content
    
    init(_ recordToggleLabel: String,
         disableRecord: Bool,
         pickerSourceLabel: String,
         selection: Binding<SelectionValue>,
         menuLabel: String,
         isRecording: Bool,
         recordingIcon: String,
         notRecordingIcon: String,
         isOn: Binding<Bool>,
         @ViewBuilder content: @escaping () -> Content
    ) {
        self.recordToggleLabel = recordToggleLabel
        self.selection = selection
        self.isOn = isOn
        self.disableRecord = disableRecord
        self.pickerSourceLabel = pickerSourceLabel
        self.isRecording = isRecording
        self.menuLabel = menuLabel
        self.recordingIcon = recordingIcon
        self.notRecordingIcon = notRecordingIcon
        self.content = content
    }
    
    var body: some View {
        Menu {
            Toggle(
                recordToggleLabel,
                isOn: isOn,
            )
            .disabled(disableRecord)
            Picker(pickerSourceLabel, selection: selection, content: content)
                .pickerStyle(.inline)
                .disabled(isRecording)
        } label: {
            Label(menuLabel, systemImage: isRecording ? recordingIcon : notRecordingIcon)
        }
    }
}

