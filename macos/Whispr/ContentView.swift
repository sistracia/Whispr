import SwiftUI

struct ContentView: View {
    @EnvironmentObject var modelData: ModelData

    @State private var processController = AudioProcessController()
    @State private var selectedNote: Note?
    @State private var showFavoritesOnly = false

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                List(selection: $selectedNote) {
                    ForEach(modelData.notes, id: \.createdAtInt) { note in
                        NoteItem(note: note)
                            .tag(note, selectable: !modelData.isRecording)
                            .listRowSeparator(.hidden)
                    }
                }
                .frame(maxWidth: geometry.size.width * 0.25)

                Divider()

                NoteEditor(
                    note: selectedNote,
                )
                .frame(maxWidth: geometry.size.width * 0.75)
            }
        }
        .navigationTitle("Screen Capture Sample")
        .toolbar {
            if !modelData.isRecording {
                NoteActionToolbar(
                    selectedNote: $selectedNote,
                    placement: .navigation
                )
            }
            if selectedNote != nil {
                NoteVoiceToolbar(
                    processController: processController,
                    placement: .primaryAction
                )
            }
        }
        .task {
            processController.activate()
            modelData.loadNotes()
        }
    }

}

#Preview {
    let randomURL = URL(string: "random")
    let modelData = ModelData(
        notes: [
            .init(
                contents: [
                    .init(
                        timestamp: Date.now,
                        text: "Content 1"
                    )
                ],
                createdAt: Date().addingTimeInterval(1),
                fileURL: randomURL
            ),
            .init(
                contents: [
                    .init(
                        timestamp: Date.now,
                        text: "Content 2"
                    )
                ],
                createdAt: Date().addingTimeInterval(2),
                fileURL: randomURL
            ),
            .init(
                contents: [
                    .init(
                        timestamp: Date.now,
                        text: "Content 3"
                    )
                ],
                createdAt: Date().addingTimeInterval(3),
                fileURL: randomURL
            ),
            .init(
                contents: [
                    .init(
                        timestamp: Date.now,
                        text: "Content 4"
                    )
                ],
                createdAt: Date().addingTimeInterval(4),
                fileURL: randomURL
            ),
            .init(
                contents: [
                    .init(
                        timestamp: Date.now,
                        text: "Content 5"
                    )
                ],
                createdAt: Date().addingTimeInterval(5),
                fileURL: randomURL
            ),
        ],
    )

    return ContentView()
        .frame(minWidth: 480, maxHeight: 180)
        .environmentObject(modelData)
}
