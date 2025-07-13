import OSLog
import SwiftUI

enum NoteType {
    case process
    case application
    case microphone
}

@MainActor
class ModelData: ObservableObject {
    private let logger = Logger()
    private let throttler = Throttler(kWriteFileThrottle, interval: 0.5, )

    private let recordingOutputPath: String? =
        NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask,
            true
        ).last
    private let fileExtention = ".txt"

    @Published private(set) var notes: [Note] = []

    var proccessNote = ""
    var isProccessRecording = false

    var applicationNote = ""
    var isApplicationRecording = false

    var microphoneNote = ""
    var isMicrophoneRecording = false

    @Published private(set) var isRecording = false
    @Published private(set) var latestNote = ""

    init(notes: [Note] = [], isRecording: Bool = false) {
        self.notes = notes
        self.isRecording = isRecording
    }

    func loadNotes() {
        guard let dirPath = self.dirURL()
        else { return }

        var notes: [Note] = []

        do {
            let contentURLs = try FileManager.default.contentsOfDirectory(
                at: dirPath,
                includingPropertiesForKeys: []
            )
            for contentURL in contentURLs {
                guard
                    let createdAt = ISO8601DateFormatter().date(
                        from: contentURL.lastPathComponent
                    )
                else { continue }

                let content = try String(
                    contentsOf: contentURL,
                    encoding: .utf8
                )
                let noteContent = NoteContent(text: content)
                let note = Note(
                    content: [noteContent],
                    createdAt: createdAt,
                    fileURL: contentURL
                )
                notes.append(note)
            }
        } catch {
            self.logger.error(
                "Error loading the notes: \(error.localizedDescription)"
            )
        }

        self.notes = notes
    }

    func writeNote(_ newContent: String, type: NoteType) {
        self.startRecording(type: type)

        switch type {
        case .process:
            self.proccessNote = newContent
        case .application:
            self.applicationNote = newContent
        case .microphone:
            self.microphoneNote = newContent
        }

        //        let foo = self.trimContent(self.proccessNote)
        //        debugPrint(foo)
        self.latestNote = self.formatNoteContent(
            processNote: self.proccessNote,
            applicationNote: self.applicationNote,
            microphoneNote: self.microphoneNote
        )
        //        guard let noteAt = notes[safe: at]
        //        else { return }
        //
        //        let lastNoteIndex = noteAt.content.count - 1
        //        guard var lastNote = noteAt.content[safe: lastNoteIndex]
        //        else { return }
        //
        //        lastNote.text = newContent
        //        notes[safe: at]?.content[safe: lastNoteIndex] = lastNote
        //
        //        guard let fileURL = notes[safe: at]?.fileURL
        //        else { return }

        //        self.writeFile(newContent, url: fileURL)
    }

    private func trimContent(_ content: String) -> [String] {
        let maxContentLength = 500

        var splitedContent: [String] = []
        var tmpContent = content
        var maxContentCap = min(tmpContent.count, maxContentLength)

        while !tmpContent.isEmpty {
            splitedContent.append(tmpContent.substring(to: maxContentCap))
            tmpContent = tmpContent.substring(from: maxContentCap)
            maxContentCap = min(tmpContent.count, maxContentLength)
        }

        return splitedContent
    }

    private func formatNoteContent(
        processNote: String,
        applicationNote: String,
        microphoneNote: String
    ) -> String {
        var formattedNote = ""
        if !processNote.isEmpty {
            formattedNote += "Process Note:\n\(processNote)\n\n"
        }

        if !applicationNote.isEmpty {
            formattedNote += "Application Note:\n\(applicationNote)\n\n"
        }

        if !microphoneNote.isEmpty {
            formattedNote += "Microphone Note:\n\(microphoneNote)\n\n"
        }

        return formattedNote
    }

    func startRecording(type: NoteType) {
        switch type {
        case .process:
            self.isProccessRecording = true
        case .application:
            self.isApplicationRecording = true
        case .microphone:
            self.isMicrophoneRecording = true
        }

        self.isRecording =
            self.isProccessRecording
            || self.isApplicationRecording
            || self.isMicrophoneRecording
    }

    func stopRecording(type: NoteType) {
        switch type {
        case .process:
            self.isProccessRecording = false
        case .application:
            self.isApplicationRecording = false
        case .microphone:
            self.isMicrophoneRecording = false
        }

        self.isRecording =
            self.isProccessRecording
            || self.isApplicationRecording
            || self.isMicrophoneRecording
    }

    func openRecordingFolder() {
        guard let recordingOutputPath = recordingOutputPath
        else { return }

        NSWorkspace.shared.selectFile(
            nil,
            inFileViewerRootedAtPath: recordingOutputPath
        )
    }

    private func writeFile(_ content: String, url: URL) {
        throttler.throttle {
            do {
                try content.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                self.logger.error(
                    "Error creating the file: \(error.localizedDescription)"
                )
            }
        }
    }

    private func dirURL() -> URL? {
        guard let recordingOutputPath = recordingOutputPath
        else { return nil }

        let recordingOutputURL = NSURL(fileURLWithPath: recordingOutputPath)
        guard
            let writePath = recordingOutputURL.appendingPathComponent(kAppName)
        else { return nil }

        let isDirExists = FileManager.default.fileExists(atPath: writePath.path)
        if !isDirExists {
            do {
                try FileManager.default.createDirectory(
                    atPath: writePath.path,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                self.logger.error(
                    "Error creating the directory: \(error.localizedDescription)"
                )
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

        let newNote = Note(
            content: [.init(text: content)],
            createdAt: currentDate,
            fileURL: fileURL
        )
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
            self.logger.error(
                "Error deleting file: \(error.localizedDescription)"
            )
        }
    }

    func deleteNote(note: Note) {
        guard let deletedIndex = self.notes.firstIndex(of: note)
        else { return }

        self.deleteNote(at: deletedIndex)
    }
}
