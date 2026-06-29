import Foundation
import SwiftData

class AIService: ObservableObject {
    @Published var isProcessing = false

    // 模拟从录音文本提取结构化摘要
    func generateSummary(for record: VisitRecord, completion: @escaping () -> Void) {
        isProcessing = true

        // 在真实场景中，这里会先调用语音转文字（STT），然后将文本发送给 LLM
        // 这里模拟网络延迟和 AI 处理过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            // 模拟 AI 提取的结构化数据
            record.doctorAdvice = "近期注意休息，避免剧烈运动。每日早晚监测血压，记录在册。"
            record.aiSummary = "患者主诉头晕、乏力，初步诊断为高血压引起的自主神经功能紊乱。"

            // 模拟 AI 识别出的新用药
            let newMed = Medication(name: "硝苯地平", dose: "30mg · 每日一次")
            record.medications.append(newMed)

            self.isProcessing = false
            completion()
        }
    }

    // 预留：真实 API 调用接口模板
    private func callRealLLM(text: String) async throws -> String {
        // let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        // var request = URLRequest(url: url)
        // ... 配置 API Key 和 Prompt ...
        return ""
    }
}
