import SwiftUI

struct NoteEditorContents: View {
    @EnvironmentObject var modelData: ModelData
    var noteIndex: Int

    var body: some View {
        VStack(alignment: .leading) {
            List {
                if let note = modelData.notes[safe: noteIndex] {
                    ForEach(0..<note.content.count, id: \.self) { index in
                        let noteText = note.content[index].text
                        Text(noteText)
                            .listRowSeparator(.hidden)
                    }
                    Text(modelData.latestNote)
                        .listRowSeparator(.hidden)
                }
            }
        }
    }
}

#Preview {
    let note = Note(
        content: [
            .init(text: "Content 1"),
            .init(text: "Content 2"),
            .init(text: "Content 3"),
            .init(text: "Content 4"),
            .init(text: "Content 5"),
        ],
        createdAt: Date(),
        fileURL: URL(string: "random")
    )

    let modelData = ModelData(notes: [note])

    return NoteEditorContents(noteIndex: 0)
        .frame(minWidth: 480, maxHeight: 180)
        .environmentObject(modelData)
}
