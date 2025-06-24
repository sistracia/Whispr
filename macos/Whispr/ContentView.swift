import SwiftUI

struct ContentView: View {
    @EnvironmentObject var modelData: ModelData
    
    @State private var processController = AudioProcessController()
    
    @State private var processRecorder = ProcessTapRecorder(speechRecognizer: SpeechRecognizer())
    @State private var appRecorder = ProcessTapRecorder(speechRecognizer: SpeechRecognizer())
    @StateObject private var micRecorder = MicRecorder(speechRecognizer: SpeechRecognizer())
    
    @State private var selectedNote: Note?
    @State private var showFavoritesOnly = false
    
    var isUnauthorized: Bool {
        let canRecognize =  SpeechRecognizer.authorized
        let canRecordMic = MicRecorder.authorized
//        let canRecordTap = isStreamDetected
        return !canRecognize || !canRecordMic
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                List(selection: $selectedNote)  {
                    ForEach(modelData.notes, id: \.createdAtInt) { note in
                        NoteItem(note: note)
                            .tag(note)
                            .listRowSeparator(.hidden)
                    }
                }
                .frame(maxWidth: geometry.size.width * 0.25)
                
                Divider()
                
                NoteEditor(note: selectedNote,
                           processRecorder: processRecorder,
                           appRecorder: appRecorder,
                           micRecorder: micRecorder)
                .frame(maxWidth: geometry.size.width * 0.75)
            }
        }
        .navigationTitle("Screen Capture Sample")
        .toolbar {
            NoteActionToolbar(selectedNote: $selectedNote, placement: .navigation)
            NoteVoiceToolbar(note: selectedNote,
                             processController: processController,
                             processRecorder: $processRecorder,
                             appRecorder: $appRecorder,
                             micRecorder: micRecorder,
                             placement: .primaryAction)
        }
        .task {
            processController.activate()
            modelData.loadNotes()
        }
    }
    
}


#Preview {
    let randomURL = URL(string: "random")
    let modelData = ModelData()
    modelData.notes = [
        .init(content: ["Content 1"], createdAt: Date().addingTimeInterval(1), fileURL: randomURL),
        .init(content: ["Content 2"], createdAt: Date().addingTimeInterval(2), fileURL: randomURL),
        .init(content: ["Content 3"], createdAt: Date().addingTimeInterval(3), fileURL: randomURL),
        .init(content: ["Content 4"], createdAt: Date().addingTimeInterval(4), fileURL: randomURL),
        .init(content: ["Content 5"], createdAt: Date().addingTimeInterval(5), fileURL: randomURL),
        .init(content: ["Content 6"], createdAt: Date().addingTimeInterval(6), fileURL: randomURL),
        .init(content: ["Content 7"], createdAt: Date().addingTimeInterval(7), fileURL: randomURL),
        .init(content: ["Content 8"], createdAt: Date().addingTimeInterval(8), fileURL: randomURL),
        .init(content: ["Content 9"], createdAt: Date().addingTimeInterval(9), fileURL: randomURL),
        .init(content: ["Content 10000"], createdAt: Date().addingTimeInterval(10), fileURL: randomURL),
    ]
    
    return ContentView()
        .frame(minWidth: 480, maxHeight: 180)
        .environmentObject(modelData)
}
