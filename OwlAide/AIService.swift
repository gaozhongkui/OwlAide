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
            DispatchQueue.main.async {
                self.isProcessing = false
                completion()
            }
            return
        }

        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = docsURL.appendingPathComponent(audioPath)

        speechRecognizer.transcribeFile(url: audioURL) { [weak self] transcribedText in
            guard let self = self, !transcribedText.isEmpty else {
                DispatchQueue.main.async {
                    self?.isProcessing = false
                    completion()
                }
                return
            }

            // 优先尝试远程 LLM，失败回退本地 NLP
            Task { @MainActor in
                if let remoteResult = await self.callRemoteLLM(text: transcribedText),
                   let parsed = self.parseRemoteLLMResult(remoteResult) {
                    record.aiSummary = parsed.diagnosis
                    record.doctorAdvice = parsed.advice
                    for med in parsed.medications {
                        record.medications.append(Medication(name: med.name, dose: med.dose))
                    }
                } else {
                    // 回退到本地 NLP
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

    // MARK: - 本地 NLP 分析（增强版：扩展医疗关键词库 + 用药知识库）

    private func analyzeLocally(_ text: String) -> (summary: String, advice: String, medications: [(name: String, dose: String)]) {
        let sentences = splitSentences(text)

        var summarySentences: [String] = []
        var adviceSentences: [String] = []

        // 医嘱关键词（大幅扩展）
        let adviceKeywords = [
            // 行为类
            "注意", "不要", "避免", "建议", "坚持", "按时", "监测", "检查", "复查",
            // 用药类
            "服用", "用药", "吞服", "含服", "外用", "涂抹", "注射",
            // 时间类
            "每日", "每天", "早晚", "早上", "晚上", "睡前", "空腹", "饭后", "餐前", "餐后",
            "一天", "两次", "三次", "每周", "隔天",
            // 饮食类
            "少盐", "少油", "清淡", "忌口", "戒烟", "戒酒", "控制饮食",
            // 运动类
            "散步", "运动", "锻炼", "休息", "静养",
            // 血压/指标类
            "血压", "血糖", "血脂", "记录", "测量", "高压", "低压", "收缩压", "舒张压"
        ]

        for sentence in sentences {
            let lower = sentence.lowercased()
            if adviceKeywords.contains(where: { lower.contains($0) }) {
                adviceSentences.append(sentence)
            } else {
                summarySentences.append(sentence)
            }
        }

        let summary = summarySentences.isEmpty ? text : summarySentences.joined(separator: "\n")
        let advice = adviceSentences.isEmpty ? "请遵医嘱，按时服药，定期复查。" : adviceSentences.joined(separator: "\n")

        // 常用药物库（大幅扩展）
        let medications = extractMedications(from: text)

        return (summary, advice, medications)
    }

    private func extractMedications(from text: String) -> [(name: String, dose: String)] {
        let medDatabase: [(String, String)] = [
            // 降压药
            ("硝苯地平", "请遵医嘱"), ("氨氯地平", "请遵医嘱"), ("非洛地平", "请遵医嘱"),
            ("氯沙坦", "请遵医嘱"), ("缬沙坦", "请遵医嘱"), ("厄贝沙坦", "请遵医嘱"),
            ("卡托普利", "请遵医嘱"), ("依那普利", "请遵医嘱"), ("贝那普利", "请遵医嘱"),
            ("美托洛尔", "请遵医嘱"), ("比索洛尔", "请遵医嘱"),
            // 降脂药
            ("阿托伐他汀", "请遵医嘱"), ("瑞舒伐他汀", "请遵医嘱"), ("辛伐他汀", "请遵医嘱"),
            // 降糖药
            ("二甲双胍", "请遵医嘱"), ("阿卡波糖", "请遵医嘱"), ("格列美脲", "请遵医嘱"),
            ("胰岛素", "请遵医嘱"), ("达格列净", "请遵医嘱"),
            // 抗血小板
            ("阿司匹林", "请遵医嘱"), ("氯吡格雷", "请遵医嘱"), ("替格瑞洛", "请遵医嘱"),
            // 心脑血管
            ("硝酸甘油", "请遵医嘱"), ("单硝酸异山梨酯", "请遵医嘱"), ("曲美他嗪", "请遵医嘱"),
            ("华法林", "请遵医嘱"), ("利伐沙班", "请遵医嘱"), ("达比加群", "请遵医嘱"),
            // 利尿剂
            ("呋塞米", "请遵医嘱"), ("氢氯噻嗪", "请遵医嘱"), ("螺内酯", "请遵医嘱"),
            // 其他
            ("地高辛", "请遵医嘱"), ("胺碘酮", "请遵医嘱"), ("普罗帕酮", "请遵医嘱")
        ]

        var result: [(name: String, dose: String)] = []
        for (name, dose) in medDatabase {
            if text.contains(name) && !result.contains(where: { $0.name == name }) {
                result.append((name, dose))
            }
        }
        return result
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

    // MARK: - 远程 LLM API 调用（可配置）

    /// 远程 LLM 服务端点（支持 OpenAI 兼容 API）
    /// 在 AppSettings 中配置 baseURL 和 apiKey 即可启用
    struct RemoteLLMConfig {
        var baseURL: String  // 如 "https://api.openai.com/v1"
        var apiKey: String
        var model: String    // 如 "gpt-4o"

        static var fromSettings: RemoteLLMConfig? {
            let base = UserDefaults.standard.string(forKey: "llm_base_url") ?? ""
            let key = UserDefaults.standard.string(forKey: "llm_api_key") ?? ""
            let model = UserDefaults.standard.string(forKey: "llm_model") ?? "gpt-4o"
            guard !base.isEmpty, !key.isEmpty else { return nil }
            return RemoteLLMConfig(baseURL: base, apiKey: key, model: model)
        }
    }

    /// 调用远程 LLM 生成结构化就诊摘要
    /// 如果未配置远程 API，自动回退到本地 NLP
    func callRemoteLLM(text: String) async -> String? {
        guard let config = RemoteLLMConfig.fromSettings else { return nil }

        let prompt = """
        你是一位专业医疗助手。请从以下就诊对话中提取结构化信息，用 JSON 格式返回：
        {
          "diagnosis": "诊断结论（一句话）",
          "advice": "医生叮嘱（要点列表，用\\n分隔）",
          "medications": [{"name": "药名", "dose": "用法用量"}]
        }
        只返回 JSON，不要其他内容。

        对话内容：
        \(text)
        """

        let url = URL(string: "\(config.baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "model": config.model,
            "messages": [["role": "system", "content": "你是医疗助手，只返回 JSON。"],
                         ["role": "user", "content": prompt]],
            "temperature": 0.3
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        guard let (data, _) = try? await URLSession.shared.data(for: request) else { return nil }

        // 解析 OpenAI 响应
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }
        return nil
    }

    /// 解析远程 LLM 返回的 JSON 为结构化数据
    private func parseRemoteLLMResult(_ jsonString: String) -> (diagnosis: String, advice: String, medications: [(name: String, dose: String)])? {
        // 去除 markdown 代码块标记
        var cleaned = jsonString
        if cleaned.hasPrefix("```") {
            cleaned = cleaned.replacingOccurrences(of: "```json", with: "")
            cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        }
        guard let data = cleaned.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }

        let diagnosis = json["diagnosis"] as? String ?? ""
        let advice = json["advice"] as? String ?? ""
        var medications: [(name: String, dose: String)] = []
        if let meds = json["medications"] as? [[String: Any]] {
            for m in meds {
                let name = m["name"] as? String ?? ""
                let dose = m["dose"] as? String ?? "请遵医嘱"
                medications.append((name, dose))
            }
        }
        return (diagnosis, advice, medications)
    }
}
