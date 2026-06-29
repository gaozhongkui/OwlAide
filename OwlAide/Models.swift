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
    var syncCount: Int = 0
    var lastSyncDate: Date?
    var isEmergencyContact: Bool = false

    init(name: String, relation: String, role: FamilyRole = .child, phoneNumber: String = "", isEmergency: Bool = false) {
        self.name = name
        self.relation = relation
        self.role = role.rawValue
        self.phoneNumber = phoneNumber
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
