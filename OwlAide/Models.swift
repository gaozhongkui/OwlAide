import Foundation
import SwiftData

enum FamilyRole: String, Codable, CaseIterable {
    case caregiver = "Primary Caregiver"
    case child = "Child"
    case spouse = "Spouse"
    case other = "Other"
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

    // Preparation Phase Data
    var symptoms: [String] = []
    @Relationship(deleteRule: .cascade) var medications: [Medication] = []
    var questions: [String] = []

    // Recording & Summary
    var audioPath: String?
    var aiSummary: String?
    var doctorAdvice: String = ""

    // Shared Status
    var isSharedWithFamily: Bool = true

    init(department: String, hospital: String) {
        self.department = department
        self.hospital = hospital
    }
}

// MARK: - VisitRecord ↔ JSON Serialization (for CloudKit transfer)

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
        // Restore medication info (create temporary Medication objects for display)
        record.medications = dto.medications.map { Medication(name: $0.name, dose: $0.dose) }
        return record
    }
}

// MARK: - Serializable DTOs

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

// MARK: - Original Data Model

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
