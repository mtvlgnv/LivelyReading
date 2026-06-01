import AVFoundation

/// Speaks a word aloud. Used by the pronunciation button in the definition
/// sheet. A single shared synthesizer avoids overlapping utterances.
@MainActor
final class Speech {
    static let shared = Speech()
    private let synth = AVSpeechSynthesizer()

    private init() {}

    func speak(_ text: String, languageCode: String? = nil) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if synth.isSpeaking {
            synth.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: trimmed)
        if let code = languageCode, code != "auto",
           let voice = AVSpeechSynthesisVoice(language: code) {
            utterance.voice = voice
        }
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92
        synth.speak(utterance)
    }
}
