import Foundation
import SwiftData
import Combine
import NaturalLanguage

class AIService: ObservableObject {
    @Published var isProcessing = false

    private let speechRecognizer = SpeechRecognizer()

    /// 从录音文件生成就诊摘要：
    /// 1. 使用系统 Speech 框架将录音转文字
    /// 2. 使用系统 NaturalLanguage 框架做本地关键词提取
    /// 3. 填充 VisitRecord 的摘要、医嘱和用药信息
    func generateSummary(for record: VisitRecord, completion: @escaping () -> Void) {
        isProcessing = true

        guard let audioPath = record.audioPath, !audioPath.isEmpty else {
            // 无录音文件，直接完成
            DispatchQueue.main.async {
                self.isProcessing = false
                completion()
            }
            return
        }

        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = docsURL.appendingPathComponent(audioPath)

        speechRecognizer.transcribeFile(url: audioURL) { [weak self] transcribedText in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if !transcribedText.isEmpty {
                    let analysis = self.analyzeLocally(transcribedText)
                    record.aiSummary = analysis.summary
                    record.doctorAdvice = analysis.advice
                    for med in analysis.medications {
                        record.medications.append(Medication(name: med.name, dose: med.dose))
                    }
                }

                self.isProcessing = false
                completion()
            }
        }
    }

    // MARK: - 本地 NLP 分析

    private func analyzeLocally(_ text: String) -> (summary: String, advice: String, medications: [(name: String, dose: String)]) {
        // 拆分为句子
        let sentences = splitSentences(text)

        // 简单规则：识别医嘱关键词
        var summarySentences: [String] = []
        var adviceSentences: [String] = []
        let adviceKeywords = ["注意", "不要", "避免", "建议", "坚持", "按时", "监测", "检查", "复查", "服用", "用药", "每日", "早晚", "空腹", "饭后", "睡前"]

        for sentence in sentences {
            let lower = sentence.lowercased()
            if adviceKeywords.contains(where: { lower.contains($0) }) {
                adviceSentences.append(sentence)
            } else {
                summarySentences.append(sentence)
            }
        }

        let summary = summarySentences.isEmpty ? text : summarySentences.joined(separator: "\n")
        let advice = adviceSentences.isEmpty ? "请遵医嘱，按时服药。" : adviceSentences.joined(separator: "\n")

        // 关键词匹配提取药物（作为补充，主要用药仍由用户在准备阶段手动拍照添加）
        let medKeywords = ["硝苯地平", "阿司匹林", "氯沙坦", "氨氯地平", "二甲双胍", "阿卡波糖", "胰岛素", "他汀", "辛伐他汀", "阿托伐他汀", "瑞舒伐他汀"]
        var medications: [(name: String, dose: String)] = []
        for kw in medKeywords {
            if text.contains(kw) && !medications.contains(where: { $0.name == kw }) {
                medications.append((name: kw, dose: "请遵医嘱"))
            }
        }

        return (summary, advice, medications)
    }

    private func splitSentences(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text

        var sentences: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !sentence.isEmpty {
                sentences.append(sentence)
            }
            return true
        }
        return sentences
    }

    // MARK: - 预留：远程 LLM API 调用

    private func callRealLLM(text: String) async throws -> String {
        // let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        // var request = URLRequest(url: url)
        // request.httpMethod = "POST"
        // request.setValue("Bearer YOUR_API_KEY", forHTTPHeaderField: "Authorization")
        // request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // let body: [String: Any] = [
        //     "model": "gpt-4o",
        //     "messages": [["role": "user", "content": "请从以下就诊对话中提取摘要和医嘱：\(text)"]]
        // ]
        // request.httpBody = try JSONSerialization.data(withJSONObject: body)
        // let (data, _) = try await URLSession.shared.data(for: request)
        // return String(data: data, encoding: .utf8) ?? ""
        return ""
    }
}
