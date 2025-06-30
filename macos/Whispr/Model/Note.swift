import SwiftUI

struct Note {
    var content: [NoteContent]
    
    let createdAt: Date
    let fileURL: URL?
    
    var createdAtInt: Int {
        Int(self.createdAt.timeIntervalSince1970)
    }
    
    var title: String {
        createdAt.ISO8601Format()
    }
}

extension Note: Hashable {}

struct NoteContent {
    var text: String
}

extension NoteContent: Hashable {}

private struct SelectedNoteKey: FocusedValueKey {
    typealias Value = Binding<Note>
}

extension FocusedValues {
    var selectedNote: Binding<Note>? {
        get { self[SelectedNoteKey.self] }
        set { self[SelectedNoteKey.self] = newValue }
    }
}
