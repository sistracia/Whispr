import SwiftUI

struct NoteEditorContents: View {
    @EnvironmentObject var modelData: ModelData
    var noteIndex: Int

    var body: some View {
        VStack(alignment: .leading) {
            List {
                Text(modelData.formattedNote)
                  .listRowSeparator(.hidden)
            }
        }
    }
}

#Preview {
    let note = Note(
        contents: [
            .init(
                timestamp: Date.now,
                text: "Content 1"
            ),
            .init(
                timestamp: Date.now,
                text: "Content 2"
            ),
            .init(
                timestamp: Date.now,
                text: "Content 3"
            ),
            .init(
                timestamp: Date.now,
                text: "Content 4"
            ),
            .init(
                timestamp: Date.now,
                text: "Content 5"
            ),
        ],
        createdAt: Date(),
        fileURL: URL(string: "random")
    )

    let modelData = ModelData(notes: [note])

    return NoteEditorContents(noteIndex: 0)
        .frame(minWidth: 480, maxHeight: 180)
        .environmentObject(modelData)
}
