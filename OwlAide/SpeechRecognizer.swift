import Foundation
import Combine
import Speech
import AVFoundation

/// 封装系统 Speech 框架，提供实时语音识别和音频文件转文字能力
class SpeechRecognizer: ObservableObject {
    @Published var recognizedText = ""
    @Published var isRecognizing = false
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    // MARK: - 权限

    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
            }
        }
    }

    // MARK: - 实时流式识别（用于按住说话）

    func startLiveRecognition() throws {
        stopLiveRecognition()

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        isRecognizing = true
        recognizedText = ""

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self?.recognizedText = result.bestTranscription.formattedString
                }
            }
            if error != nil {
                self?.stopLiveRecognition()
            }
        }
    }

    func stopLiveRecognition() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isRecognizing = false

        // 释放音频会话，避免阻塞其他音频组件
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - 音频文件转文字（用于就诊录音后处理）

    func transcribeFile(url: URL, completion: @escaping (String) -> Void) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            completion("")
            return
        }

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        request.taskHint = .dictation

        speechRecognizer.recognitionTask(with: request) { result, error in
            if let result = result, result.isFinal {
                completion(result.bestTranscription.formattedString)
            } else if error != nil {
                completion("")
            }
        }
    }
}
