import SwiftUI

struct NoteEditorContents: View {
    @EnvironmentObject var modelData: ModelData
    var noteIndex: Int

    var body: some View {
        if let note = modelData.notes[safe: noteIndex] {
            let textBinding = Binding<String>(
                get: { note.content.map { $0.text } .joined(separator: "\n") },
                set: { modelData.writeNote($0, at: note.content.count - 1) }
            )

            TextEditor(text: textBinding)
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

    let modelData = ModelData()
    modelData.notes = [
        note
    ]

    return NoteEditorContents(noteIndex: 0)
        .frame(minWidth: 480, maxHeight: 180)
        .environmentObject(modelData)
}
