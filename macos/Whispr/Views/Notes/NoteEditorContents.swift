import SwiftUI

struct NoteEditorContents: View {
    @EnvironmentObject var modelData: ModelData
    var noteIndex: Int
    
    var body: some View {
        VStack(alignment: .leading) {
            List {
                if !modelData.notes.isEmpty {
                    let note = modelData.notes[noteIndex]
                    ForEach(0..<note.content.count, id: \.self) { index in
                        let textBinding = Binding<String>(get: { note.content[index] },
                                                          set: { modelData.writeNote($0, at: index) })
                        TextEditor(text: textBinding)
                            .fixedSize(horizontal: false, vertical: true)
                            .scrollDisabled(true)
                            .listRowSeparator(.hidden)
                    }
                }
            }
        }
    }
}

