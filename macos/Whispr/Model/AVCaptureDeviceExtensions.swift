import AVFoundation

extension AVCaptureDevice {
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
