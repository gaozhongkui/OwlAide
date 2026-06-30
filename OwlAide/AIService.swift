import Foundation
import SwiftData
import Combine
import NaturalLanguage

class AIService: ObservableObject {
    @Published var isProcessing = false

    private let speechRecognizer = SpeechRecognizer()

    /// Generate visit summary from recording:
    /// 1. Transcribe audio to text using Speech framework
    /// 2. Extract keywords using NaturalLanguage framework
    /// 3. Populate VisitRecord summary, advice, and medications
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

            // Priority: Remote LLM, fallback to local NLP
            Task { @MainActor in
                if let remoteResult = await self.callRemoteLLM(text: transcribedText),
                   let parsed = self.parseRemoteLLMResult(remoteResult) {
                    record.aiSummary = parsed.diagnosis
                    record.doctorAdvice = parsed.advice
                    for med in parsed.medications {
                        record.medications.append(Medication(name: med.name, dose: med.dose))
                    }
                } else {
                    // Fallback to local NLP
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

    // MARK: - Local NLP Analysis (Extended medical keyword & knowledge base)

    private func analyzeLocally(_ text: String) -> (summary: String, advice: String, medications: [(name: String, dose: String)]) {
        let sentences = splitSentences(text)

        var summarySentences: [String] = []
        var adviceSentences: [String] = []

        // Advice Keywords
        let adviceKeywords = [
            // Behavior
            "notice", "don't", "avoid", "suggest", "insist", "on time", "monitor", "check", "follow-up",
            // Medication
            "take", "medication", "swallow", "topical", "apply", "injection",
            // Time
            "daily", "every day", "morning", "evening", "night", "before bed", "empty stomach", "after meals",
            "twice", "thrice", "weekly", "every other day",
            // Diet
            "low salt", "low oil", "light diet", "abstain", "quit smoking", "quit alcohol", "diet control",
            // Exercise
            "walk", "exercise", "rest", "recuperate",
            // BP/Indicators
            "blood pressure", "blood sugar", "lipids", "record", "measure", "systolic", "diastolic"
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
        let advice = adviceSentences.isEmpty ? "Please follow doctor's orders, take medication on time, and have regular check-ups." : adviceSentences.joined(separator: "\n")

        // Medication database
        let medications = extractMedications(from: text)

        return (summary, advice, medications)
    }

    private func extractMedications(from text: String) -> [(name: String, dose: String)] {
        let medDatabase: [(String, String)] = [
            // Antihypertensives
            ("Nifedipine", "As prescribed"), ("Amlodipine", "As prescribed"), ("Felodipine", "As prescribed"),
            ("Losartan", "As prescribed"), ("Valsartan", "As prescribed"), ("Irbesartan", "As prescribed"),
            ("Captopril", "As prescribed"), ("Enalapril", "As prescribed"), ("Benazepril", "As prescribed"),
            ("Metoprolol", "As prescribed"), ("Bisoprolol", "As prescribed"),
            // Statins
            ("Atorvastatin", "As prescribed"), ("Rosuvastatin", "As prescribed"), ("Simvastatin", "As prescribed"),
            // Diabetes
            ("Metformin", "As prescribed"), ("Acarbose", "As prescribed"), ("Glimepiride", "As prescribed"),
            ("Insulin", "As prescribed"), ("Dapagliflozin", "As prescribed"),
            // Antiplatelet
            ("Aspirin", "As prescribed"), ("Clopidogrel", "As prescribed"), ("Ticagrelor", "As prescribed"),
            // Cardiovascular
            ("Nitroglycerin", "As prescribed"), ("Isosorbide Mononitrate", "As prescribed"), ("Trimetazidine", "As prescribed"),
            ("Warfarin", "As prescribed"), ("Rivaroxaban", "As prescribed"), ("Dabigatran", "As prescribed"),
            // Diuretics
            ("Furosemide", "As prescribed"), ("Hydrochlorothiazide", "As prescribed"), ("Spironolactone", "As prescribed"),
            // Others
            ("Digoxin", "As prescribed"), ("Amiodarone", "As prescribed"), ("Propafenone", "As prescribed")
        ]

        var result: [(name: String, dose: String)] = []
        let lowerText = text.lowercased()
        for (name, dose) in medDatabase {
            if lowerText.contains(name.lowercased()) && !result.contains(where: { $0.name == name }) {
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

    // MARK: - Remote LLM API Call

    /// Remote LLM config (OpenAI compatible)
    struct RemoteLLMConfig {
        var baseURL: String  // e.g. "https://api.openai.com/v1"
        var apiKey: String
        var model: String    // e.g. "gpt-4o"

        static var fromSettings: RemoteLLMConfig? {
            let base = UserDefaults.standard.string(forKey: "llm_base_url") ?? ""
            let key = UserDefaults.standard.string(forKey: "llm_api_key") ?? ""
            let model = UserDefaults.standard.string(forKey: "llm_model") ?? "gpt-4o"
            guard !base.isEmpty, !key.isEmpty else { return nil }
            return RemoteLLMConfig(baseURL: base, apiKey: key, model: model)
        }
    }

    /// Call remote LLM to generate structured summary
    func callRemoteLLM(text: String) async -> String? {
        guard let config = RemoteLLMConfig.fromSettings else { return nil }

        let prompt = """
        You are a professional medical assistant. Please extract structured information from the following clinical dialogue and return it in JSON format:
        {
          "diagnosis": "Diagnosis (one sentence)",
          "advice": "Doctor's advice (bullet points, separated by \\n)",
          "medications": [{"name": "Medication Name", "dose": "Usage/Dosage"}]
        }
        Return ONLY the JSON, nothing else.

        Dialogue:
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
            "messages": [["role": "system", "content": "You are a medical assistant. Return only JSON."],
                         ["role": "user", "content": prompt]],
            "temperature": 0.3
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        guard let (data, _) = try? await URLSession.shared.data(for: request) else { return nil }

        // Parse OpenAI response
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }
        return nil
    }

    /// Parse JSON returned by LLM
    private func parseRemoteLLMResult(_ jsonString: String) -> (diagnosis: String, advice: String, medications: [(name: String, dose: String)])? {
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
                let dose = m["dose"] as? String ?? "As prescribed"
                medications.append((name, dose))
            }
        }
        return (diagnosis, advice, medications)
    }
}
