import SwiftUI

struct NoteActionToolbar: ToolbarContent {
    @EnvironmentObject var modelData: ModelData
    @Binding var selectedNote: Note?
    
    var placement: ToolbarItemPlacement
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: placement) {
            Button {
                addNote()
            } label: {
                Label("Create a Note", systemImage: "square.and.pencil")
                    .labelStyle(.iconOnly)
            }
            
            if selectedNote != nil {
                Button {
                    deleteNote()
                } label: {
                    Label("Delete Note", systemImage: "trash")
                        .labelStyle(.iconOnly)
                }
            }
        }
    }
    
    private func addNote() {
        let newNote = Note(content: ["New Note"],
                           createdAt: Int(Date().timeIntervalSince1970))
        modelData.notes.insert(newNote, at: 0)
        selectedNote = newNote
    }
    
    private func deleteNote() {
        guard let currentSelectedNote = selectedNote,
              let deletedIndex = modelData.notes.firstIndex(of: currentSelectedNote)
        else { return }
        
        selectedNote = nil
        modelData.notes.remove(at: deletedIndex)
    }
}
