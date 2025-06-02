import SwiftUI

struct NoteItem: View {
    var note: Note
    
    var title: String {
        let prefixLength = 10

        if note.content.count > prefixLength {
            return "\(note.content.prefix(prefixLength))..."
        }

        return note.content
    }
    
    var body: some View {
        VStack {
            Text(title)
        }
    }
}

#Preview {
    NoteItem(note: .init(content: "Test1234567", createdAt: 1))
        .frame(minWidth: 480, maxHeight: 180)
}
