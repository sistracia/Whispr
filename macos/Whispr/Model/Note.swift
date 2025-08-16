import SwiftUI

struct Note {
    var contents: [NoteContent]

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

enum NoteType {
    case process
    case application
    case microphone
}

struct NoteContent {
    var timestamp: Date
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
