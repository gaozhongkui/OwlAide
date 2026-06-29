import Foundation
import SwiftData

@Model
class VisitRecord {
    var id: UUID = UUID()
    var date: Date = Date()
    var department: String = ""
    var hospital: String = ""

    // 准备阶段数据
    var symptoms: [String] = []
    var medications: [Medication] = []
    var questions: [String] = []

    // 录音与摘要
    var audioPath: String?
    var aiSummary: String? // 存储 JSON 格式的摘要或纯文本
    var doctorAdvice: String = ""

    init(department: String, hospital: String) {
        self.department = department
        self.hospital = hospital
    }
}

@Model
class Medication {
    var name: String = ""
    var dose: String = ""

    init(name: String, dose: String) {
        self.name = name
        self.dose = dose
    }
}
