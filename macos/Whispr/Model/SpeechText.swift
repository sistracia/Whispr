import Foundation
import OSLog
import Speech

enum AudioSourceType {
    case audioProcess(AudioProcess)
    case captureDevice(AVCaptureDevice)
}

protocol SpeechProcessor {
    func start(
        audioSource: AudioSourceType,
        locale: Locale?,
        transcriptionResult: @escaping (String, TimeInterval) -> Void
    ) async -> Error?
    func stop() async -> Error?
}

class SpeechText: ObservableObject {
    fileprivate let logger = Logger()

    private(set) var recognizer = SpeechRecognizer()

    private(set) var isRecording = false
    private(set) var fullText = ""

    // The transcribing result will have cut in the middle of trascription for the utterance
    private var utterances: [String] = [""]

    private(set) var streamSource: StreamSource

    init(streamSource: StreamSource) {
        self.streamSource = streamSource
    }

    fileprivate func startTranscribing(
        locale: Locale?,
        transcriptionResult: @escaping (String, TimeInterval) -> Void
    ) async -> Error? {
        self.isRecording = true

        let isTranscribingStarted = await self.recognizer
            .startTranscribing(
                locale: locale
            ) { [weak self] result, error in
                guard let self = self else { return }
                if error != nil {
                    return
                }

                let transcription =
                    result?.bestTranscription.formattedString ?? ""
                let segments = result?.bestTranscription.segments ?? []

                self.processRecognition(
                    transcription: transcription,
                    segments: segments,
                )
                transcriptionResult(
                    self.fullText,
                    segments.last?.timestamp ?? 0.0
                )
            }

        // Handle error
        if !isTranscribingStarted {
            return NSError()
        }

        return nil
    }

    private func processRecognition(
        transcription: String,
        segments: [SFTranscriptionSegment]
    ) {
        let lastIndex = self.utterances.count - 1
        self.utterances[safe: lastIndex] = transcription
        self.fullText = utterances.joined(separator: " ")

        let confidenceSample = segments.first?.confidence ?? 0.0
        let isUtteranceFinal = confidenceSample > 0.0 ? true : false
        if isUtteranceFinal {
            self.utterances.append("")
        }
    }

    func stop() async -> Error? {
        self.isRecording = false
        await self.streamSource.stopStream()
        self.recognizer.stopTranscribing()
        return nil
    }

}

class AudioProcessSpeechText: SpeechText, SpeechProcessor {
    private(set) var audioSource: AudioProcessStreamSource

    init(audioSource: AudioProcessStreamSource) {
        self.audioSource = audioSource
        super.init(streamSource: audioSource)
    }

    func start(
        audioSource: AudioSourceType,
        locale: Locale?,
        transcriptionResult: @escaping (String, TimeInterval) -> Void
    )
        async -> Error?
    {
        switch audioSource {
        case .audioProcess(let audioProcess):
            var error = await super.startTranscribing(
                locale: locale,
                transcriptionResult: transcriptionResult
            )
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

        case .captureDevice:
            return NSError(
                domain: "InvalidAudioSource",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "AudioProcessSpeechText cannot handle AVCaptureDevice"
                ]
            )
        }

    }
}

class CaptureDeviceSpeechText: SpeechText, SpeechProcessor {
    private(set) var audioSource: CaptureDeviceStreamSource

    init(audioSource: CaptureDeviceStreamSource) {
        self.audioSource = audioSource
        super.init(streamSource: audioSource)
    }

    func start(
        audioSource: AudioSourceType,
        locale: Locale?,
        transcriptionResult: @escaping (String, TimeInterval) -> Void
    ) async -> Error? {
        switch audioSource {
        case .captureDevice(let captureDevice):
            var error = await super.startTranscribing(
                locale: locale,
                transcriptionResult: transcriptionResult
            )
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
        case .audioProcess:
            return NSError(
                domain: "InvalidAudioSource",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "CaptureDeviceSpeechText cannot handle AudioProcess"
                ]
            )
        }
    }
}
