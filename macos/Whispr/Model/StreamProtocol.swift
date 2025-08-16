import Foundation
import Speech

enum StreamState {
    case stopped
    case streaming
}

protocol StreamSource {
    var state: StreamState { get }
    var audioLevelsProvider: AudioLevelsProvider { get }

    func startStream(
        locale: Locale?,
        resultHandler: @escaping ([SFTranscriptionSegment], (any Error)?) ->
            Void
    ) async -> Error?

    func stopStream() async
}
