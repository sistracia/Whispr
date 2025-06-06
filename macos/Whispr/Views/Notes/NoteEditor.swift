import SwiftUI

struct NoteEditor: View {
    @EnvironmentObject var modelData: ModelData
    @ObservedObject var micRecorder: MicRecorder
    var note: Note?
    
    var noteIndex: Int? {
        guard let note = note,
              let noteIndex = modelData.notes.firstIndex(where: { $0.createdAt == note.createdAt })
        else { return nil }
        
        return noteIndex
    }
    
    var body: some View {
        if let noteIndex = noteIndex {
            GeometryReader { geometry in
                VStack {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading) {
                            Text("App Sound Meter")
                            AudioLevelsView(audioLevelsProvider: micRecorder.audioLevelsProvider)
                        }
                        VStack(alignment: .leading) {
                            Text("Desktop Sound Meter")
                            AudioLevelsView(audioLevelsProvider: micRecorder.audioLevelsProvider)
                        }
                        VStack(alignment: .leading) {
                            Text("Microphone Meter")
                            AudioLevelsView(audioLevelsProvider: micRecorder.audioLevelsProvider)
                        }
                    }
                    .padding(3)
                    Divider()
                    VStack(alignment: .leading) {
                        List {
                            ForEach(0..<$modelData.notes[noteIndex].content.count, id: \.self) { index in
                                TextEditor(text: $modelData.notes[noteIndex].content[index])
                                    .fixedSize(horizontal: false, vertical: true)
                                    .scrollDisabled(true)
                                    .listRowSeparator(.hidden)
                            }
                        }
                    }
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
    @StateObject var micRecorder = MicRecorder()
    let modelData = ModelData()
    
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
                    createdAt: 1)
    modelData.notes = [
        note
    ]
    
    return NoteEditor(micRecorder: micRecorder, note: note, )
        .frame(minWidth: 480, maxHeight: 180)
        .environmentObject(modelData)
}
