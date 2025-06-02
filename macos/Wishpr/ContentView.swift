import SwiftUI

struct ContentView: View {
    @EnvironmentObject var modelData: ModelData
    
    @State private var selectedNote: Note?
    @State private var showFavoritesOnly = false
    
    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                List(selection: $selectedNote)  {
                    ForEach(modelData.notes, id: \.createdAt) { note in
                        NoteItem(note: note)
                            .tag(note)
                            .listRowSeparator(.hidden)
                    }
                }
                .frame(maxWidth: proxy.size.width * 0.25)
                
                Divider()
                
                VStack {
                    if let selectedNote = selectedNote {
                        NoteEditor(note: selectedNote)
                    } else {
                        Text("Select or Create a Note")
                    }
                }
                .frame(maxWidth: proxy.size.width * 0.75)
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        let newNote = Note(content: "New Note",
                                           createdAt: Int(Date().timeIntervalSince1970))
                        modelData.notes.append(newNote)
                        selectedNote = newNote
                    } label: {
                        Label("Create a Note", systemImage: "square.and.pencil")
                            .labelStyle(.iconOnly)
                    }
                }
            }
        }
    }
}


#Preview {
    var modelData = ModelData()
    modelData.notes = [
        .init(content: "Content 1", createdAt: 1),
        .init(content: "Content 2", createdAt: 2),
        .init(content: "Content 3", createdAt: 3),
        .init(content: "Content 4", createdAt: 4),
        .init(content: "Content 5", createdAt: 5),
        .init(content: "Content 6", createdAt: 6),
        .init(content: "Content 7", createdAt: 7),
        .init(content: "Content 8", createdAt: 8),
        .init(content: "Content 9", createdAt: 9),
        .init(content: "Content 10000", createdAt: 10),
    ]
    
    return ContentView()
        .frame(minWidth: 480, maxHeight: 180)
        .environmentObject(modelData)
}
