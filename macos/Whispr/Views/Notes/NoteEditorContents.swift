import SwiftUI

struct NoteEditorContents: View {
    @EnvironmentObject var modelData: ModelData
    var noteIndex: Int
    
    var body: some View {
        VStack(alignment: .leading) {
            List {
                if !modelData.notes.isEmpty {
                    ForEach(0..<modelData.notes[noteIndex].content.count, id: \.self) { index in
                        let textBinding = Binding<String>(get: { modelData.notes.isEmpty ? "" : modelData.notes[noteIndex].content[index] },
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

