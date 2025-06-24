import SwiftUI

struct NoteEditor: View {
    @EnvironmentObject var modelData: ModelData
    
    var note: Note?
    var processRecorder: ProcessTapRecorder
    var appRecorder: ProcessTapRecorder
    @ObservedObject var micRecorder: MicRecorder
    
    @State private var isShowingProcessSoundPopover: Bool = false
    @State private var isShowingAppSoundPopover: Bool = false
    @State private var isShowingMicSoundPopover: Bool = false
    
    var noteIndex: Int? {
        guard let note = note,
              let noteIndex = modelData.notes.firstIndex(where: { $0.createdAtInt == note.createdAtInt })
        else { return nil }
        
        return noteIndex
    }
    
    var body: some View {
        if let noteIndex = noteIndex {
            GeometryReader { geometry in
                VStack {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Process Sound Meter")
                                if processRecorder.state == .streaming && processRecorder.audioLevelsProvider.audioLevels.level.isZero {
                                    Button {
                                        isShowingProcessSoundPopover = true
                                    } label:  {
                                        Label("Show Process Capture Error", systemImage: "exclamationmark.triangle")
                                            .labelStyle(.iconOnly)
                                    }
                                    .foregroundStyle(.red)
                                    .buttonStyle(.borderless)
                                    .popover(
                                        isPresented: $isShowingProcessSoundPopover, arrowEdge: .bottom
                                    ) {
                                        Text("""
Open System Settings and grant the permission, go to:
1. Privacy & Security > Screen & System Recording > System Audio Recording Only.
2. Privacy & Security > Speech Recognition.
""")
                                        .padding()
                                    }
                                }
                            }
                            AudioLevelsView(audioLevelsProvider: processRecorder.audioLevelsProvider)
                        }
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Application Sound Meter")
                                if appRecorder.state == .streaming && appRecorder.audioLevelsProvider.audioLevels.level.isZero {
                                    Button {
                                        isShowingAppSoundPopover = true
                                    } label:  {
                                        Label("Show Application Capture Error", systemImage: "exclamationmark.triangle")
                                            .labelStyle(.iconOnly)
                                    }
                                    .foregroundStyle(.red)
                                    .buttonStyle(.borderless)
                                    .popover(
                                        isPresented: $isShowingAppSoundPopover, arrowEdge: .bottom
                                    ) {
                                        Text("""
Open System Settings and grant the permission, go to:
1. Privacy & Security > Screen & System Recording > System Audio Recording Only.
2. Privacy & Security > Speech Recognition.
""")
                                        .padding()
                                    }
                                }
                            }
                            AudioLevelsView(audioLevelsProvider: appRecorder.audioLevelsProvider)
                        }
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Microphone Meter")
                                if micRecorder.state == .streaming && micRecorder.audioLevelsProvider.audioLevels.level.isZero {
                                    Button {
                                        isShowingMicSoundPopover = true
                                    } label:  {
                                        Label("Show Microphone Capture Error", systemImage: "exclamationmark.triangle")
                                            .labelStyle(.iconOnly)
                                    }
                                    .foregroundStyle(.red)
                                    .buttonStyle(.borderless)
                                    .popover(
                                        isPresented: $isShowingMicSoundPopover, arrowEdge: .bottom
                                    ) {
                                        Text("""
Open System Settings and grant the permission, go to:
1. Privacy & Security > Microphone.
2. Privacy & Security > Speech Recognition.
""")
                                        .padding()
                                    }
                                    .labelsVisibility(.hidden)
                                }
                            }
                            AudioLevelsView(audioLevelsProvider: micRecorder.audioLevelsProvider)
                        }
                    }
                    .padding(3)
                    Divider()
                    NoteEditorContents(noteIndex: noteIndex)
                        .frame(minHeight: geometry.size.height)
                }
                .background(.background)
            }
        } else {
            Text("Select or Create a Note")
        }
    }
}

#Preview {
    @Previewable @State var processRecorder = ProcessTapRecorder(speechRecognizer: SpeechRecognizer())
    @Previewable @State var appRecorder = ProcessTapRecorder(speechRecognizer: SpeechRecognizer())
    @Previewable @StateObject var micRecorder = MicRecorder(speechRecognizer: SpeechRecognizer())
    
    let note = Note(content: [
        "Content 1",
        "Content 2",
        "Content 3",
        "Content 4",
        "Content 5",
        "Content 6",
        "Content 7",
        "Content 8",
        "Content 9",
        "Content 10",
        "Content 11",
        "Content 12",
        "Content 13",
        "Content 14",
    ],
                    createdAt: Date(),
                    fileURL: URL(string: "random"))
    
    let modelData = ModelData()
    modelData.notes = [
        note
    ]
    
    return NoteEditor(note: note,
                      processRecorder: processRecorder,
                      appRecorder: appRecorder,
                      micRecorder: micRecorder,)
    .frame(minWidth: 480, maxHeight: 180)
    .environmentObject(modelData)
}
