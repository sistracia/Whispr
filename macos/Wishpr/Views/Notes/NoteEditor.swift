import SwiftUI

struct NoteEditor: View {
    var note: Note
    @EnvironmentObject var modelData: ModelData
    
    var landmarkIndex: Int {
        modelData.notes.firstIndex(where: { $0.createdAt == note.createdAt })!
    }
    
    var body: some View {
        VStack {
            TextEditor(text: $modelData.notes[landmarkIndex].content)
                .padding()
        }
        .background(.background)
    }
}

#Preview {
    var modelData = ModelData()
    
    var note = Note(content: "Content 1", createdAt: 1)
    modelData.notes = [
        note
    ]
    
    return NoteEditor(note: note)
        .frame(minWidth: 480, maxHeight: 180)
        .environmentObject(modelData)
}
