import SwiftUI

struct Note {
    var content: [String]
    let createdAt: Int
}

extension Note: Hashable {}

private struct SelectedNoteKey: FocusedValueKey {
    typealias Value = Binding<Note>
}

extension FocusedValues {
    var selectedNote: Binding<Note>? {
        get { self[SelectedNoteKey.self] }
        set { self[SelectedNoteKey.self] = newValue }
    }
}
