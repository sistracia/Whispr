import SwiftUI
import OSLog

@MainActor
class ModelData: ObservableObject {
    private let logger = Logger()
    private let throttler = Throttler(kWriteFileThrottle, interval: 0.5, )
    
    private let recordingOutputPath: String? = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last
    private let fileExtention = ".txt"
    
    @Published var notes: [Note] = []
    
    func loadNotes() {
        guard let dirPath = self.dirURL()
        else { return }
        
        var notes: [Note] = []
        
        do {
            let contentURLs = try FileManager.default.contentsOfDirectory(at: dirPath, includingPropertiesForKeys: [])
            for contentURL in contentURLs {
                guard let createdAt = ISO8601DateFormatter().date(from: contentURL.lastPathComponent)
                else { continue }
                
                let content = try String(contentsOf: contentURL, encoding: .utf8)
                notes.append(.init(content: [content], createdAt: createdAt, fileURL: contentURL))
            }
        } catch {
            self.logger.error("Error loading the notes: \(error.localizedDescription)")
        }
        
        self.notes = notes
    }
    
    func writeNote(_ newContent: String, at: Int) {
        if notes.isEmpty {
            return
        }
        if notes[at].content.isEmpty {
            return
        }
        notes[at].content[notes[at].content.count - 1] = newContent
        
        guard let fileURL = notes[at].fileURL
        else { return }
        
        self.writeFile(newContent, url: fileURL)
    }
    
    func openRecordingFolder() {
        guard let recordingOutputPath = recordingOutputPath
        else { return }
        
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: recordingOutputPath)
    }
    
    private func writeFile(_ content: String, url: URL) {
        throttler.throttle {
            do {
                try content.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                self.logger.error("Error creating the file: \(error.localizedDescription)")
            }
        }
    }
    
    private func dirURL() -> URL? {
        guard let recordingOutputPath = recordingOutputPath
        else { return nil }
        
        let recordingOutputURL = NSURL(fileURLWithPath: recordingOutputPath)
        guard let writePath = recordingOutputURL.appendingPathComponent(kAppName)
        else { return nil }

        let isDirExists = FileManager.default.fileExists(atPath: writePath.path)
        if !isDirExists{
            do {
                try FileManager.default.createDirectory(atPath: writePath.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                self.logger.error("Error creating the directory: \(error.localizedDescription)")
            }
        }
        
        return writePath
    }
    
    private func createFileURL(_ title: String) -> URL? {
        guard let directoryURL = dirURL()
        else { return nil }
        
        return directoryURL.appendingPathComponent(title + fileExtention)
    }
    
    
    func initNewNote() -> Note {
        let currentDate = Date()
        let content = "New Note"
        let fileURL = self.createFileURL(currentDate.ISO8601Format())
        
        if let fileURL = fileURL {
            self.writeFile(content, url: fileURL)
        }
        
        let newNote = Note(content: [content],
                           createdAt: currentDate,
                           fileURL: fileURL)
        self.notes.insert(newNote, at: 0)
        return newNote
    }
    
    func deleteNote(at index: Int) {
        let deletedNote = self.notes.remove(at: index)
        
        guard let deletedNoteURL = deletedNote.fileURL
        else { return }
        
        do {
            try FileManager.default.removeItem(at: deletedNoteURL)
        } catch {
            self.logger.error("Error deleting file: \(error.localizedDescription)")
        }
    }
    
    func deleteNote(note: Note) {
        guard let deletedIndex = self.notes.firstIndex(of: note)
        else { return }
        
        self.deleteNote(at: deletedIndex)
    }
}
