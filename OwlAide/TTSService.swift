import AVFoundation
import Combine

/// Voice feedback service: TTS reading, helping senior users with poor vision.
/// Uses system built-in voice, works offline.
class TTSService: ObservableObject {
    static let shared = TTSService()

    private let synthesizer = AVSpeechSynthesizer()

    /// Read text (Auto-detect language, slower rate)
    func speak(_ text: String) {
        // Avoid overlapping speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        // Use the current system language for the voice
        utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.language.languageCode?.identifier ?? "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.7  // Slower, elder-friendly
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        // Ensure audio session is active
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        synthesizer.speak(utterance)
    }

    /// Read text with completion callback
    func speak(_ text: String, completion: @escaping () -> Void) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.language.languageCode?.identifier ?? "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.7

        synthesizer.speak(utterance)

        // Delayed callback (simple approximation)
        let duration = Double(text.count) * 0.08
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            completion()
        }
    }

    /// Stop speaking
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
