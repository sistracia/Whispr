import SwiftUI

struct NoteActionToolbar: ToolbarContent {
    @EnvironmentObject var modelData: ModelData
    @Binding var selectedNote: Note?
    
    var placement: ToolbarItemPlacement
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: placement) {
            Button {
                modelData.openRecordingFolder()
            } label: {
                Label("Open in Finder", systemImage: "folder")
                    .labelStyle(.iconOnly)
            }
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
        selectedNote = modelData.initNewNote()
    }
    
    private func deleteNote() {
        guard let currentSelectedNote = selectedNote
        else { return }
        
        modelData.deleteNote(note: currentSelectedNote)
        selectedNote = nil
    }
}
