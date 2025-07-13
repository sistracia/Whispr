import AVFoundation
import Combine
import Foundation
import OSLog
import SwiftUI

@Observable
final class MicRecorder: NSObject, StreamSource {
    private let logger = Logger()

    private(set) var state = StreamState.stopped

    private(set) var audioLevelsProvider = AudioLevelsProvider()
    private let powerMeter = PowerMeter()
    private var audioMeterCancellable: AnyCancellable?

    private let captureSession = AVCaptureSession()
    private var captureAudioDataOutput = AVCaptureAudioDataOutput()

    private var lastChunkCount = 0
    private var transribeResultChunk: [String] = []
    private var resultHandler: ((String, (any Error)?) -> Void)? = nil
    private var transribeCancellable: AnyCancellable?

    var captureDevice: AVCaptureDevice?

    private let speechRecognizer: SpeechRecognizer

    init(speechRecognizer: SpeechRecognizer) {
        self.speechRecognizer = speechRecognizer
    }

    private func emitTranscribedResult() {
        transribeCancellable = Timer.publish(
            every: 0.1,
            on: .main,
            in: .common
        ).autoconnect().sink { [weak self] _ in
            guard let self = self else { return }
            self.resultHandler?(
                self.transribeResultChunk.joined(separator: " "),
                nil
            )
        }
    }

    private func startAudioMetering() {
        audioMeterCancellable = Timer.publish(
            every: 0.1,
            on: .main,
            in: .common
        ).autoconnect().sink { [weak self] _ in
            guard let self = self else { return }
            self.audioLevelsProvider.audioLevels = self.powerMeter.levels
        }
    }

    @MainActor
    func startStream(
        locale: Locale? = nil,
        resultHandler: @escaping (String, (any Error)?) -> Void
    ) async -> Error? {
        let isAllowed = await AVCaptureDevice.requestAccess(for: .audio)
        if !isAllowed {
            return "Microphone access is not allowed"
        }

        guard let captureDevice = self.captureDevice
        else { return "Capture device not found" }

        self.state = .streaming
        self.captureSession.inputs.forEach {
            captureSession.removeInput($0)
        }

        let isCaptureAllowed = self.requestCapture(captureDevice: captureDevice)
        if !isCaptureAllowed {
            return "Capture not allowed"
        }

        self.resultHandler = resultHandler
        let isTranscribingStarted = await speechRecognizer.startTranscribing(
            locale: locale
        ) {
            // The transcribing result will have cut in the middle of trascription
            result,
            error in
            if let error = error {
                self.logger.error(
                    "Error when transcribing: \(error.localizedDescription)"
                )
            }

            let transcription = result?.bestTranscription.formattedString ?? ""
            let currentChunkCount =
                result?.bestTranscription.segments.count ?? 0

            let chunkCountDiff = currentChunkCount - self.lastChunkCount
            if (currentChunkCount == 1 && chunkCountDiff < 0)
                || self.transribeResultChunk.isEmpty
            {
                self.transribeResultChunk.append("")
                self.lastChunkCount = 0
            }

            let lastIndex = self.transribeResultChunk.count - 1
            self.transribeResultChunk[safe: lastIndex] = transcription
            self.lastChunkCount = currentChunkCount
        }

        // Handle error
        if !isTranscribingStarted {
            self.logger.error("Failed to start transcribing")
        }

        self.startAudioMetering()
        self.emitTranscribedResult()

        return nil
    }

    func requestCapture(captureDevice: AVCaptureDevice) -> Bool {
        do {
            // Wrap the audio device in a capture device input.
            let audioInput = try AVCaptureDeviceInput(device: captureDevice)

            // If the input can be added, add it to the session.
            if self.captureSession.canAddInput(audioInput) {
                self.captureSession.addInput(audioInput)
            }
            self.captureSession.startRunning()

            // Create audio output
            let audioQueue = DispatchQueue(label: kAudioStreamingQueue)
            self.captureAudioDataOutput.setSampleBufferDelegate(
                self,
                queue: audioQueue
            )

            if self.captureSession.canAddOutput(self.captureAudioDataOutput) {
                self.captureSession.addOutput(self.captureAudioDataOutput)
            }

            return true
        } catch {
            self.logger.error(
                "Failed to start stream: \(error.localizedDescription)"
            )

            return false
        }
    }

    @MainActor
    func stopStream() {
        if self.state == .stopped {
            return
        }

        self.state = .stopped
        self.audioLevelsProvider.audioLevels = AudioLevels.zero

        self.captureSession.stopRunning()
        self.speechRecognizer.stopTranscribing()

        self.audioMeterCancellable?.cancel()
        self.audioMeterCancellable = nil

        self.transribeCancellable?.cancel()
        self.transribeCancellable = nil
        self.resultHandler = nil
    }
}

extension MicRecorder: AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput: CMSampleBuffer,
        from: AVCaptureConnection
    ) {
        Task { @MainActor in
            self.powerMeter.process(buffer: didOutput)
            self.speechRecognizer.processAudioBuffer(didOutput)
        }
    }
}

extension MicRecorder {
    static var captureDevices: [AVCaptureDevice] {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone],
            mediaType: .audio,
            position: .unspecified
        )
        return discoverySession.devices
    }

    static var authorized: Bool {
        AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }
}
