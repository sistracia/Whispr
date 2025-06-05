import AVFoundation
import AVFAudio
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
    
    private let powerMeter = PowerMeter()
    @Published private(set) var audioLevelsProvider = AudioLevelsProvider()
    private var audioMeterCancellable: AnyCancellable?
    
    private let audioEngine: AVAudioEngine
    private let audioNodeBus: AVAudioNodeBus = 0
    
    var canRecord: Bool {
        get {
            return AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        }
    }
    
    override init() {
        self.audioEngine = AVAudioEngine()
    }
    
    private func startAudioMetering() {
        audioMeterCancellable = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self else { return }
            self.audioLevelsProvider.audioLevels = self.powerMeter.levels
        }
    }
    
    func startStreaming() {
        do {
            self.state = .streaming
            
            let audioFormat =  AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44_100.0, channels: 1, interleaved: false)
            self.audioEngine.inputNode.installTap(onBus: audioNodeBus, bufferSize: 4096 , format: audioFormat, block: { [weak self] buffer, _ in
                guard let self = self else { return }
                self.powerMeter.process(buffer: buffer)
            })
            
            try self.audioEngine.start()
            
            self.startAudioMetering()
        } catch {
            logger.error("Error start streaming: \(error.localizedDescription)")
            self.state = .stopped
        }
    }
    
    func stopStreaming() {
        self.audioMeterCancellable?.cancel()
        self.audioEngine.inputNode.removeTap(onBus: audioNodeBus)
        self.audioEngine.stop()
        self.powerMeter.processSilence()
        self.state = .stopped
    }
}

