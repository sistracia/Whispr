import Combine
import OSLog
import Speech
import SwiftUI

@MainActor
class ModelData: ObservableObject {
    private let logger = Logger()
    private let throttler = Throttler(kWriteFileThrottle, interval: 0.5)

    private let recordingOutputPath: String? =
        NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask,
            true
        ).last
    private let fileExtention = ".txt"

    @Published private(set) var notes: [Note] = []

    private(set) var processSpeech = AudioProcessSpeechText(
        audioSource: ProcessTapRecorder()
    )
    private(set) var applicationSpeech = AudioProcessSpeechText(
        audioSource: ProcessTapRecorder()
    )
    private(set) var microphoneSpeech = CaptureDeviceSpeechText(
        audioSource: MicRecorder()
    )

    var isProcessStreaming: Bool {
        processSpeech.streamSource.state == .streaming
    }

    var isApplicationStreaming: Bool {
        applicationSpeech.streamSource.state == .streaming
    }

    var isMicrophoneStreaming: Bool {
        microphoneSpeech.streamSource.state == .streaming
    }

    var isStreaming: Bool {
        isProcessStreaming || isApplicationStreaming || isMicrophoneStreaming
    }

    var isRecording: Bool {
        return self.processSpeech.isRecording
            || self.applicationSpeech.isRecording
            || self.microphoneSpeech.isRecording
    }

    @Published var formattedNote: String = ""
    private var formattedNoteCancellable: AnyCancellable?

    init(notes: [Note] = []) {
        self.notes = notes
    }

    func toggleRecording(
        type: NoteType,
        isRecording: Bool,
        audioProcess: AudioProcess,
        locale: Locale?,
    ) async -> Error? {
        let error = await {
            switch type {
            case .process:
                return await self.processSpeech.toggleStart(
                    isRecording: isRecording,
                    audioProcess: audioProcess,
                    locale: locale
                )
            case .application:
                return await self.applicationSpeech.toggleStart(
                    isRecording: isRecording,
                    audioProcess: audioProcess,
                    locale: locale
                )
            default:
                return nil
            }
        }()

        if error != nil {
            return error
        }

        if isRecording {
            self.startFormatNote()
        } else {
            self.stopFormatNote()
        }

        return nil
    }

    func toggleRecording(
        type: NoteType,
        isRecording: Bool,
        captureDevice: AVCaptureDevice,
        locale: Locale?,
    ) async -> Error? {
        let error = await {
            switch type {
            case .microphone:
                return await self.microphoneSpeech.toggleStart(
                    isRecording: isRecording,
                    captureDevice: captureDevice,
                    locale: locale
                )
            default:
                return nil
            }
        }()

        if error != nil {
            return error
        }

        if isRecording {
            self.startFormatNote()
        } else {
            self.stopFormatNote()
        }

        return nil
    }

    private func startFormatNote() {
        formattedNoteCancellable = Timer.publish(
            every: 1,
            on: .main,
            in: .common
        ).autoconnect().sink { [weak self] _ in
            guard let self = self else { return }

            var formattedNote = ""
            for index in stride(
                from: 0,
                to: self.processSpeech.timestamps.count,
                by: 1
            ) {
                let timestamp = self.processSpeech.timestamps[index]
                let startIndex = min(
                    timestamp.range.startIndex,
                    self.processSpeech.fullText.count
                )
                let endIndex = min(
                    timestamp.range.endIndex,
                    self.processSpeech.fullText.count
                )
                formattedNote += self.processSpeech.fullText.substring(
                    with: startIndex..<endIndex
                )
            }
            self.formattedNote = formattedNote
        }
    }

    private func stopFormatNote() {
        if self.isRecording {
            return
        }

        formattedNoteCancellable?.cancel()
        formattedNoteCancellable = nil
    }

    private func doingSomething() {
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
                let noteContent = NoteContent(
                    timestamp: Date.now,
                    text: content
                )
                let note = Note(
                    contents: [noteContent],
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
            contents: [],
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
