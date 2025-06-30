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

    var captureDevice: AVCaptureDevice?

    private let speechRecognizer: SpeechRecognizer

    init(speechRecognizer: SpeechRecognizer) {
        self.speechRecognizer = speechRecognizer
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
        do {
            self.captureSession.inputs.forEach {
                captureSession.removeInput($0)
            }

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

            let isTranscribingStarted =
                await speechRecognizer.startTranscribing(locale: locale) {
                    result,
                    error in
                    if let error = error {
                        self.logger.error(
                            "Error when transcribing: \(error.localizedDescription)"
                        )
                    }

                    let transcription =
                        result?.bestTranscription.formattedString ?? ""
                    resultHandler(transcription, error)

                }

            // Handle error
            if !isTranscribingStarted {
                self.logger.error("Failed to start transcribing")
            }
            
            self.startAudioMetering()

            return nil
        } catch {
            self.logger.error(
                "Failed to start stream: \(error.localizedDescription)"
            )
            self.state = .stopped
            return "Failed to start the stream"
        }
    }

    @MainActor
    func stopStream() {
        if self.state == .stopped {
            return
        }

        self.state = .stopped
        self.captureSession.stopRunning()
        self.speechRecognizer.stopTranscribing()
        self.audioLevelsProvider.audioLevels = AudioLevels.zero
        self.audioMeterCancellable?.cancel()
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
