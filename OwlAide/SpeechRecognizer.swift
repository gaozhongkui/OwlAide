import Foundation
import Combine
import Speech
import AVFoundation

/// Wraps the system Speech framework to provide real-time speech recognition and audio file transcription.
class SpeechRecognizer: ObservableObject {
    @Published var recognizedText = ""
    @Published var isRecognizing = false
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    // MARK: - Permissions

    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
            }
        }
    }

    // MARK: - Real-time Streaming Recognition (Hold-to-Talk)

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

        // Release audio session to avoid blocking other components
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Audio File Transcription (Post-visit processing)

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
