import AVFoundation
import Foundation

enum StreamState {
    case stopped
    case streaming
}

protocol StreamSource {
    var state: StreamState { get }
    var audioLevelsProvider: AudioLevelsProvider { get }
    func stopStream() async
}

protocol AudioProcessStreamSource: StreamSource {
    func startStream(
        audioProcess: AudioProcess,
        resultHandler: @escaping (AVAudioPCMBuffer) -> Void
    ) async -> Error?
}

protocol CaptureDeviceStreamSource: StreamSource {
    func startStream(
        captureDevice: AVCaptureDevice,
        resultHandler: @escaping (AVAudioPCMBuffer) -> Void
    ) async -> Error?
}
