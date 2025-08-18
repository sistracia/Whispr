import Combine
import OSLog
import Speech
import SwiftUI

struct SpeechRange {
    var startIndex: Int
    var endIndex: Int
}

struct SpeechTimestamp {
    var timestamp: Date
    var range: SpeechRange
}

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

    private(set) var processAudioSource: ProcessTapRecorder
    private(set) var processSpeech: AudioProcessSpeechText

    private(set) var applicationAudioSource: ProcessTapRecorder
    private(set) var applicationSpeech: AudioProcessSpeechText

    private(set) var microphoneAudioSource: MicRecorder
    private(set) var microphoneSpeech: CaptureDeviceSpeechText

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
    private(set) var timestamps: [SpeechTimestamp] = []
    private var startRecognitionTime: Date?

    init(notes: [Note] = []) {
        self.notes = notes

        self.processAudioSource = ProcessTapRecorder()
        self.applicationAudioSource = ProcessTapRecorder()
        self.microphoneAudioSource = MicRecorder()

        self.processSpeech = AudioProcessSpeechText(
            audioSource: self.processAudioSource
        )
        self.applicationSpeech = AudioProcessSpeechText(
            audioSource: self.applicationAudioSource
        )
        self.microphoneSpeech = CaptureDeviceSpeechText(
            audioSource: self.microphoneAudioSource
        )
    }

    func toggleRecording(
        isRecording: Bool,
        audioSource: AudioSourceType,
        locale: Locale?,
        speechProcessor: SpeechProcessor
    ) async -> Error? {
        if isRecording {
            self.startRecognitionTime = Date.now
            let error = await speechProcessor.start(
                audioSource: audioSource,
                locale: locale
            ) { [weak self] transcription, segmentTimestamp in
                guard let self = self else { return }
                self.transcriptionResult(
                    transcription: transcription,
                    segmentTimestamp: segmentTimestamp
                )
            }

            if error != nil {
                return error
            }

            self.startFormatNote()
        } else {
            self.startRecognitionTime = nil
            let error = await speechProcessor.stop()

            if error != nil {
                return error
            }

            self.stopFormatNote()
        }

        return nil
    }

    private func transcriptionResult(
        transcription: String,
        segmentTimestamp: TimeInterval,
    ) {
        guard var startRecognitionTime = self.startRecognitionTime
        else { return }

        startRecognitionTime = startRecognitionTime.addingTimeInterval(
            segmentTimestamp
        )

        let startIndex = self.timestamps.last?.range.endIndex ?? 0
        let speechRange = SpeechRange(
            startIndex: startIndex,
            endIndex: max(transcription.count, startIndex)
        )
        let speechTimestamp = SpeechTimestamp(
            timestamp: startRecognitionTime,
            range: speechRange
        )

        self.timestamps.append(speechTimestamp)
        self.startRecognitionTime = startRecognitionTime
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
                to: self.timestamps.count,
                by: 1
            ) {
                let timestamp = self.timestamps[index]
                let startIndex = min(
                    timestamp.range.startIndex,
                    self.microphoneSpeech.fullText.count
                )
                let endIndex = min(
                    timestamp.range.endIndex,
                    self.microphoneSpeech.fullText.count
                )
                formattedNote += self.microphoneSpeech.fullText.substring(
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
