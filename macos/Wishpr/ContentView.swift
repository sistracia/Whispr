import SwiftUI
import ScreenCaptureKit

struct ContentView: View {
    @EnvironmentObject var modelData: ModelData
    
    @StateObject var screenRecorder = ScreenRecorder()
    
    @State private var selectedNote: Note?
    @State private var showFavoritesOnly = false
    @State private var recordApp: String = AppsAvailable.none.rawValue
    @State private var recordDesktop = false
    @State private var recordMic = false
    @State private var isUnauthorized = false
    
    
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
            .navigationTitle("Screen Capture Sample")
            .toolbar {
                NoteActionToolbar(selectedNote: $selectedNote, placement: .navigation)
                NoteVoiceToolbar(screenRecorder: screenRecorder,
                                 recordApp: $recordApp,
                                 recordDesktop: $recordDesktop,
                                 recordMic: $recordMic,
                                 placement: .primaryAction)
            }
            .overlay {
                if isUnauthorized {
                    Unauthorized()
                }
            }
            .onAppear {
                Task {
                    if await screenRecorder.canRecord {
                        await screenRecorder.start()
                    } else {
                        isUnauthorized = true
                    }
                }
            }
        }
    }
    
}


#Preview {
    let modelData = ModelData()
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
