import Speech

/// A helper for transcribing speech to text using SFSpeechRecognizer and AVAudioEngine.
/// Ref: https://www.linkedin.com/pulse/transcribing-audio-text-swiftui-muhammad-asad-chattha
class SpeechRecognizer {
    
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    
    func startTranscribing(locale: Locale? = nil, _ resultHandler: @escaping (SFSpeechRecognitionResult?, (any Error)?) -> Void) async -> Bool {
        let isAllowed = await SFSpeechRecognizer.requestAccess()
        if !isAllowed {
            return false
        }
        
        var recognizer: SFSpeechRecognizer? = nil
        if let locale = locale {
            recognizer = SFSpeechRecognizer(locale: locale)
        } else {
            recognizer = SFSpeechRecognizer()
        }
        
        guard let recognizer = recognizer else {
            return false
        }
        
        if !recognizer.isAvailable {
            return false
        }
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        
        self.task = recognizer.recognitionTask(with: request, resultHandler: resultHandler)
        self.request = request
        
        return true
    }
    
    func stopTranscribing() {
        task?.cancel()
        task = nil
        request = nil
    }
    
    func processAudioBuffer(_ sampleBuffer: CMSampleBuffer) {
        self.request?.appendAudioSampleBuffer(sampleBuffer)
    }
    
    func processAudioBuffer(_ sampleBuffer: AVAudioPCMBuffer) {
        self.request?.append(sampleBuffer)
    }
}


extension SpeechRecognizer {
    static var authorized: Bool {
        get {
            SFSpeechRecognizer.authorizationStatus() == .authorized
        }
    }
    
    static var supportedLocales: [Locale] {
        get {
            SFSpeechRecognizer.supportedLocales().map { $0 }
        }
    }
}

extension SFSpeechRecognizer {
    static func requestAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
}
