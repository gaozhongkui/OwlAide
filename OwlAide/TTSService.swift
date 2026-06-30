import AVFoundation
import Combine

/// 语音反馈服务：TTS 朗读，帮助视力不佳的老年用户
/// 使用系统内置中文语音，无需网络
class TTSService: ObservableObject {
    static let shared = TTSService()

    private let synthesizer = AVSpeechSynthesizer()

    /// 朗读文本（中文，慢速）
    func speak(_ text: String) {
        // 避免重叠朗读
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.7  // 慢速，老年人友好
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        // 确保在音频会话激活时朗读
        try? AVAudioSession.sharedInstance().setActive(true)

        synthesizer.speak(utterance)
    }

    /// 朗读后执行回调
    func speak(_ text: String, completion: @escaping () -> Void) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.7

        // 使用 delegate 或 completion handler
        synthesizer.speak(utterance)

        // 延迟回调（简单近似）
        let duration = Double(text.count) * 0.08
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            completion()
        }
    }

    /// 停止朗读
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
