import SwiftUI

struct NoteItem: View {
    var note: Note
    
    var title: String {
        let prefixLength = 10
        let ellipsisContent = "..."

        guard let firstContent = note.content.first, !firstContent.isEmpty
        else { return ellipsisContent }

        if firstContent.count > prefixLength {
            return "\(firstContent.prefix(prefixLength))\(ellipsisContent)"
        }

        return firstContent
    }
    
    var body: some View {
        VStack {
            Text(title)
        }
    }
}

#Preview {
    NoteItem(note: .init(content: ["Test1234567"], createdAt: 1))
        .frame(minWidth: 480, maxHeight: 180)
}
