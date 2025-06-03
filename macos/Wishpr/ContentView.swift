import SwiftUI

struct ContentView: View {
    @EnvironmentObject var modelData: ModelData
    
    @State private var selectedNote: Note?
    @State private var showFavoritesOnly = false
    @State private var recordApp = AppsAvailable.none
    @State private var recordDesktop = false
    @State private var recordMic = false
    
    enum AppsAvailable: String, CaseIterable, Identifiable {
        case none = "<None>"
        case all = "All"
        case lakes = "Lakes"
        case rivers = "Rivers"
        case mountains = "Mountains"
        
        var id: AppsAvailable { self }
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                List(selection: $selectedNote)  {
                    ForEach(modelData.notes, id: \.createdAt) { note in
                        NoteItem(note: note)
                            .tag(note)
                            .listRowSeparator(.hidden)
                    }
                }
                .frame(maxWidth: geometry.size.width * 0.25)
                
                Divider()
                
                NoteEditor(note: selectedNote)
                    .frame(maxWidth: geometry.size.width * 0.75)
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
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
                ToolbarItemGroup(placement: .primaryAction) {
                    Menu {
                        Picker("Record App", selection: $recordApp) {
                            ForEach(AppsAvailable.allCases) { app in
                                Text(app.rawValue).tag(app)
                            }
                        }
                        .pickerStyle(.inline)
                    } label: {
                        Label("App Recorder", systemImage: "inset.filled.rectangle.badge.record")
                    }
                    Toggle(
                        "Record Desktop",
                        systemImage: "menubar.dock.rectangle.badge.record",
                        isOn: $recordDesktop
                    )
                    Toggle(
                        "Record Mic",
                        systemImage: "record.circle",
                        isOn: $recordMic
                    )
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


#Preview {
    var modelData = ModelData()
    modelData.notes = [
        .init(content: ["Content 1"], createdAt: 1),
        .init(content: ["Content 2"], createdAt: 2),
        .init(content: ["Content 3"], createdAt: 3),
        .init(content: ["Content 4"], createdAt: 4),
        .init(content: ["Content 5"], createdAt: 5),
        .init(content: ["Content 6"], createdAt: 6),
        .init(content: ["Content 7"], createdAt: 7),
        .init(content: ["Content 8"], createdAt: 8),
        .init(content: ["Content 9"], createdAt: 9),
        .init(content: ["Content 10000"], createdAt: 10),
    ]
    
    return ContentView()
        .frame(minWidth: 480, maxHeight: 180)
        .environmentObject(modelData)
}
