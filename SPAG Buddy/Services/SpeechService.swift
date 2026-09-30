import AVFoundation
import Foundation

/// Reads questions and spelling words aloud in a British English voice.
final class SpeechService {
    private let synthesizer = AVSpeechSynthesizer()
    private let voice = AVSpeechSynthesisVoice(language: "en-GB")

    func speak(_ text: String, slowly: Bool = false) {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: Self.speakable(text))
        utterance.voice = voice
        utterance.rate = slowly ? 0.36 : 0.45
        utterance.pitchMultiplier = 1.05
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    /// Turns written gaps like "______" into the word "blank" so the voice does not read out underscores.
    static func speakable(_ text: String) -> String {
        text.replacingOccurrences(of: "_+", with: " blank ", options: .regularExpression)
            .replacingOccurrences(of: "\"", with: "")
    }
}
