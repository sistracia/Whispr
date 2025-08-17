import AVFoundation
import Combine
import Foundation
import OSLog
import SwiftUI

@Observable
final class MicRecorder: NSObject, CaptureDeviceStreamSource {
    private let logger = Logger()

    private(set) var state = StreamState.stopped

    private(set) var audioLevelsProvider = AudioLevelsProvider()
    private let powerMeter = PowerMeter()
    private var audioMeterCancellable: AnyCancellable?

    private let captureSession = AVCaptureSession()
    private var captureAudioDataOutput = AVCaptureAudioDataOutput()

    private var resultHandler: ((CMSampleBuffer) -> Void)? = nil

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
        captureDevice: AVCaptureDevice,
        resultHandler: @escaping (CMSampleBuffer) -> Void
    ) async -> Error? {

        let isAllowed = await AVCaptureDevice.requestAccess(for: .audio)
        if !isAllowed {
            return "Microphone access is not allowed"
        }

        self.state = .streaming
        self.captureSession.inputs.forEach {
            captureSession.removeInput($0)
        }

        let isCaptureAllowed = self.requestCapture(captureDevice: captureDevice)
        if !isCaptureAllowed {
            return "Capture not allowed"
        }

        self.startAudioMetering()
        self.resultHandler = resultHandler

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
        self.audioMeterCancellable?.cancel()
        self.audioMeterCancellable = nil

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
            resultHandler?(didOutput)
        }
    }
}
