import Foundation
import Speech

struct SpeechRange {
    var startIndex: Int
    var endIndex: Int
}

struct SpeechTimestamp {
    var timestamp: Date
    var range: SpeechRange
}

class SpeechText {
    private(set) var isRecording = false
    private(set) var fullText = ""

    // The transcribing result will have cut in the middle of trascription for new paragraph
    private var lastTextParagraph = 0
    private var textParagraph: [[SFTranscriptionSegment]] = []

    func appendText(_ segments: [SFTranscriptionSegment]) {
        self.isRecording = true

        let segmentsCountDiff = segments.count - self.lastTextParagraph
        if (segments.count == 1 && segmentsCountDiff < 0)
            || self.textParagraph.isEmpty
        {
            self.textParagraph.append([])
            self.lastTextParagraph = 0
        }

        let lastIndex = self.textParagraph.count - 1
        self.textParagraph[safe: lastIndex] = segments
        self.lastTextParagraph = segments.count

        let newFullText = segments.map { $0.substring }.joined(separator: " ")
        let prevFullTextCount = self.fullText.count
        self.fullText = newFullText

        let speechRange = SpeechRange(
            startIndex: prevFullTextCount,
            endIndex: newFullText.count
        )

        let newTimestamp = SpeechTimestamp(
            timestamp: Date.now,
            range: speechRange
        )
    }

    func stopListening() {
        self.isRecording = false
    }
}
