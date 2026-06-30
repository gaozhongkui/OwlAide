import Foundation
import SwiftData

enum FamilyRole: String, Codable, CaseIterable {
    case caregiver = "主照顾者"
    case child = "子女"
    case spouse = "配偶"
    case other = "其他"
}

@Model
class FamilyMember {
    var id: UUID = UUID()
    var name: String = ""
    var relation: String = ""
    var role: String = FamilyRole.child.rawValue
    var phoneNumber: String = ""
    var email: String = ""
    var syncCount: Int = 0
    var lastSyncDate: Date?
    var isEmergencyContact: Bool = false

    init(name: String, relation: String, role: FamilyRole = .child, phoneNumber: String = "", email: String = "", isEmergency: Bool = false) {
        self.name = name
        self.relation = relation
        self.role = role.rawValue
        self.phoneNumber = phoneNumber
        self.email = email
        self.isEmergencyContact = isEmergency
        self.lastSyncDate = Date()
    }
}

@Model
class VisitRecord {
    var id: UUID = UUID()
    var date: Date = Date()
    var department: String = ""
    var hospital: String = ""

    // 准备阶段数据
    var symptoms: [String] = []
    @Relationship(deleteRule: .cascade) var medications: [Medication] = []
    var questions: [String] = []

    // 录音与摘要
    var audioPath: String?
    var aiSummary: String?
    var doctorAdvice: String = ""

    // 共享状态
    var isSharedWithFamily: Bool = true

    init(department: String, hospital: String) {
        self.department = department
        self.hospital = hospital
    }
}

// MARK: - VisitRecord ↔ JSON 序列化（用于 CloudKit 传输）

extension VisitRecord {
    func toJSON() -> String {
        let dto = VisitRecordDTO(
            id: id,
            date: date,
            department: department,
            hospital: hospital,
            symptoms: symptoms,
            medications: medications.map { MedicationDTO(name: $0.name, dose: $0.dose) },
            questions: questions,
            audioPath: audioPath,
            aiSummary: aiSummary,
            doctorAdvice: doctorAdvice,
            isSharedWithFamily: isSharedWithFamily
        )
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(dto),
              let json = String(data: data, encoding: .utf8) else { return "{}" }
        return json
    }

    static func fromJSON(_ json: String) -> VisitRecord? {
        guard let data = json.data(using: .utf8),
              let dto = try? JSONDecoder().decode(VisitRecordDTO.self, from: data) else { return nil }
        let record = VisitRecord(department: dto.department, hospital: dto.hospital)
        record.id = dto.id
        record.date = dto.date
        record.symptoms = dto.symptoms
        record.questions = dto.questions
        record.audioPath = dto.audioPath
        record.aiSummary = dto.aiSummary
        record.doctorAdvice = dto.doctorAdvice
        record.isSharedWithFamily = dto.isSharedWithFamily
        // 还原用药信息（创建临时 Medication 对象用于展示）
        record.medications = dto.medications.map { Medication(name: $0.name, dose: $0.dose) }
        return record
    }
}

// MARK: - 可序列化的 DTO

private struct VisitRecordDTO: Codable {
    let id: UUID
    let date: Date
    let department: String
    let hospital: String
    let symptoms: [String]
    let medications: [MedicationDTO]
    let questions: [String]
    let audioPath: String?
    let aiSummary: String?
    let doctorAdvice: String
    let isSharedWithFamily: Bool
}

private struct MedicationDTO: Codable {
    let name: String
    let dose: String
}

// MARK: - 原数据模型

@Model
class Medication {
    var name: String = ""
    var dose: String = ""
    var isTakenToday: Bool = false
    var reminderTime: String = "09:00"

    init(name: String, dose: String, isTakenToday: Bool = false) {
        self.name = name
        self.dose = dose
        self.isTakenToday = isTakenToday
    }
}
