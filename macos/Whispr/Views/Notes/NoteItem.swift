import SwiftUI

struct NoteItem: View {
    var note: Note
    
    var body: some View {
        VStack {
            Text(note.title)
        }
    }
}

#Preview {
    NoteItem(note: .init(content: ["Test1234567"],
                         createdAt: Date(),
                         fileURL: URL(string: "random")))
        .frame(minWidth: 480, maxHeight: 180)
}
