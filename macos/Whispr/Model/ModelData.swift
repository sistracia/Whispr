import SwiftUI

@MainActor
class ModelData: ObservableObject {
    @Published var notes: [Note] = []
    
    @MainActor
    func writeNote(_ newContent: String, at: Int) {
        if notes.isEmpty {
            return
        }
        if notes[at].content.isEmpty {
            return
        }
        notes[at].content[notes[at].content.count - 1] = newContent
    }
}
