import Foundation
import OSLog
import Speech

struct SpeechRange {
    var startIndex: Int
    var endIndex: Int
}

struct SpeechTimestamp {
    var timestamp: Date
    var range: SpeechRange
}

class SpeechText: ObservableObject {
    fileprivate let logger = Logger()

    private(set) var recognizer = SpeechRecognizer()

    private(set) var isRecording = false
    private(set) var fullText = ""

    private(set) var timestamps: [SpeechTimestamp] = []
    private var startRecognitionTime: Date?

    // The transcribing result will have cut in the middle of trascription for the utterance
    private var utterances: [String] = [""]

    private(set) var streamSource: StreamSource

    init(streamSource: StreamSource) {
        self.streamSource = streamSource
    }

    private func startListening() {
        self.startRecognitionTime = Date.now
        self.isRecording = true
    }

    private func stopListening() {
        self.startRecognitionTime = nil
        self.isRecording = false
    }

    private func processRecognition(result: SFSpeechRecognitionResult?) {
        let transcription =
            result?.bestTranscription.formattedString ?? ""
        let segments = result?.bestTranscription.segments ?? []

        let lastIndex = self.utterances.count - 1
        self.utterances[safe: lastIndex] = transcription
        self.fullText = utterances.joined(separator: " ")

        let confidenceSample =
            result?.bestTranscription.segments[0].confidence ?? 0.0
        let isUtteranceFinal = confidenceSample > 0.0 ? true : false
        if isUtteranceFinal {
            self.utterances.append("")
        }

        guard var startRecognitionTime = self.startRecognitionTime
        else { return }

        startRecognitionTime = startRecognitionTime.addingTimeInterval(
            segments.last?.timestamp ?? 0
        )
        let startIndex = self.timestamps.last?.range.endIndex ?? 0
        let speechRange = SpeechRange(
            startIndex: startIndex,
            endIndex: max(self.fullText.count, startIndex)
        )
        let speechTimestamp = SpeechTimestamp(
            timestamp: startRecognitionTime,
            range: speechRange
        )

        self.timestamps.append(speechTimestamp)
        self.startRecognitionTime = startRecognitionTime
    }

    fileprivate func startTranscribing(locale: Locale?) async -> Error? {
        self.startListening()

        let isTranscribingStarted = await self.recognizer
            .startTranscribing(
                locale: locale
            ) { [weak self] result, error in
                guard let self = self else { return }
                if error != nil {
                    return
                }

                self.processRecognition(result: result)
            }

        // Handle error
        if !isTranscribingStarted {
            return NSError()
        }

        return nil
    }

    func stop() async -> Error? {
        self.stopListening()
        await self.streamSource.stopStream()
        self.recognizer.stopTranscribing()
        return nil
    }

}

class AudioProcessSpeechText: SpeechText {
    private(set) var audioSource: AudioProcessStreamSource

    init(audioSource: AudioProcessStreamSource) {
        self.audioSource = audioSource
        super.init(streamSource: audioSource)
    }

    func start(audioProcess: AudioProcess, locale: Locale?) async -> Error? {
        var error = await super.startTranscribing(locale: locale)
        if error != nil {
            self.logger.error("Failed to start transcribing")
            return error
        }

        error = await self.audioSource.startStream(
            audioProcess: audioProcess,
        ) { [weak self] result in
            guard let self = self else { return }
            self.recognizer.processAudioBuffer(result)
        }

        if error != nil {
            self.logger.error("Failed to start process")
            return nil
        }

        return nil
    }

    func toggleStart(
        isRecording: Bool,
        audioProcess: AudioProcess,
        locale: Locale?,
    ) async -> Error? {
        if !isRecording {
            return await self.stop()
        }

        return await self.start(
            audioProcess: audioProcess,
            locale: locale
        )
    }
}

class CaptureDeviceSpeechText: SpeechText {
    private(set) var audioSource: CaptureDeviceStreamSource

    init(audioSource: CaptureDeviceStreamSource) {
        self.audioSource = audioSource
        super.init(streamSource: audioSource)
    }

    func start(captureDevice: AVCaptureDevice, locale: Locale?) async -> Error?
    {
        var error = await super.startTranscribing(locale: locale)
        if error != nil {
            self.logger.error("Failed to start transcribing")
            return error
        }

        error = await self.audioSource.startStream(
            captureDevice: captureDevice,
        ) { [weak self] result in
            guard let self = self else { return }
            self.recognizer.processAudioBuffer(result)
        }

        if error != nil {
            self.logger.error("Failed to start process")
            return nil
        }

        return nil
    }

    func toggleStart(
        isRecording: Bool,
        captureDevice: AVCaptureDevice,
        locale: Locale?,
    ) async -> Error? {
        if !isRecording {
            return await self.stop()
        }

        return await self.start(
            captureDevice: captureDevice,
            locale: locale
        )
    }
}
