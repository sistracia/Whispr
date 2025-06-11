import SwiftUI

struct NoteEditor: View {
    @EnvironmentObject var modelData: ModelData
    
    var note: Note?
    var processRecorder: ProcessTapRecorder
    var appRecorder: ProcessTapRecorder
    @ObservedObject var micRecorder: MicRecorder
    
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
                            Text("Process Sound Meter")
                            AudioLevelsView(audioLevelsProvider: processRecorder.audioLevelsProvider)
                        }
                        VStack(alignment: .leading) {
                            Text("Application Sound Meter")
                            AudioLevelsView(audioLevelsProvider: appRecorder.audioLevelsProvider)
                        }
                        VStack(alignment: .leading) {
                            Text("Microphone Meter")
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
