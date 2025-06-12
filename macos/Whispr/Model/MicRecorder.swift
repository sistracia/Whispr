import Foundation
import AVFoundation
import SwiftUI
import OSLog
import Combine

enum MicRecorderState {
    case stopped
    case streaming
}

@MainActor
class MicRecorder: NSObject, ObservableObject {
    private let logger = Logger()
    
    @Published private(set) var state = MicRecorderState.stopped
    
    private var meterTableAverage = MeterTable()
    private var meterTablePeak = MeterTable()
    @Published private(set) var audioLevelsProvider = AudioLevelsProvider()
    private var audioMeterCancellable: AnyCancellable?
    
    private let captureSession = AVCaptureSession()
    private var captureAudioDataOutput = AVCaptureAudioDataOutput()
    
    @Published  var captureDevice: AVCaptureDevice?
    
    private let speechRecognizer: SpeechRecognizer
    
    init(speechRecognizer: SpeechRecognizer) {
        self.speechRecognizer = speechRecognizer
    }
    
    func startStream(locale: Locale? = nil, resultHandler: @escaping (String, (any Error)?) -> Void) async -> Bool {
        let isAllowed = await AVCaptureDevice.requestAccess(for: .audio)
        if !isAllowed {
            return false
        }
        
        guard let captureDevice = self.captureDevice
        else { return false }
        
        self.state = .streaming
        do {
            self.captureSession.inputs.forEach { captureSession.removeInput($0) }
            
            // Wrap the audio device in a capture device input.
            let audioInput = try AVCaptureDeviceInput(device: captureDevice)
            // If the input can be added, add it to the session.
            if self.captureSession.canAddInput(audioInput) {
                self.captureSession.addInput(audioInput)
            }
            self.captureSession.startRunning()
            
            // Create audio output
            let audioQueue = DispatchQueue(label: kAudioStreamingQueue)
            self.captureAudioDataOutput.setSampleBufferDelegate(self, queue: audioQueue)
            
            if self.captureSession.canAddOutput(self.captureAudioDataOutput) {
                self.captureSession.addOutput(self.captureAudioDataOutput)
            }
            
            let isTranscribingStarted = await speechRecognizer.startTranscribing(locale: locale) { result, error in
                if let error = error {
                    self.logger.error("Error when transcribing: \(error.localizedDescription)")
                } else {
                    let transcription = result?.bestTranscription.formattedString ?? ""
                    resultHandler(transcription, error)
                }
            }
            
            // Handle error
            if !isTranscribingStarted {
                self.logger.error("Failed to start transcribing")
            }
            
            return true
        } catch {
            self.logger.error("Failed to start stream: \(error.localizedDescription)")
            self.state = .stopped
            return false
        }
    }
    
    func stopStream() {
        DispatchQueue.main.async {
            self.audioMeterCancellable?.cancel()
            self.captureSession.stopRunning()
            self.audioLevelsProvider.audioLevels = AudioLevels.zero
            self.state = .stopped
            self.speechRecognizer.stopTranscribing()
        }
    }
}

extension MicRecorder: AVCaptureAudioDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput: CMSampleBuffer, from: AVCaptureConnection) {
        let averagePower = didOutput.toDBFS()
        let peakPower = didOutput.toPeakDBFS()
        
        DispatchQueue.main.async {
            let audioLevels = AudioLevels(level: self.meterTableAverage.valueForPower(averagePower),
                                          peakLevel: self.meterTablePeak.valueForPower(peakPower))
            self.audioLevelsProvider.audioLevels = audioLevels
        }
        
        Task { @MainActor in
            self.speechRecognizer.processAudioBuffer(didOutput)
        }
    }
}

extension MicRecorder {
    static var captureDevices: [AVCaptureDevice] {
        get {
            let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.microphone],
                                                                    mediaType: .audio,
                                                                    position: .unspecified)
            return discoverySession.devices
        }
    }
    
    static var authorized: Bool {
        get {
            AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        }
    }
}
