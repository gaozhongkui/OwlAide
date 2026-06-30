import UserNotifications
import Foundation

/// 本地通知管理：用药提醒、复诊提醒
/// 完全本地，无需服务器，免费
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false

    // MARK: - 权限

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
            }
        }
    }

    // MARK: - 用药提醒

    /// 为指定药品创建每日定时提醒
    func scheduleMedicationReminder(medicationName: String, dose: String, timeString: String) {
        let parts = timeString.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return }

        let content = UNMutableNotificationContent()
        content.title = "💊 该吃药了"
        content.body = "\(medicationName) · \(dose)"
        content.sound = .default
        content.badge = 1

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let identifier = "medication_\(medicationName)_\(timeString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("用药提醒创建失败: \(error.localizedDescription)")
            }
        }
    }

    /// 取消某个药品的所有提醒
    func cancelMedicationReminder(medicationName: String) {
        // 根据名称模式移除
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests
                .filter { $0.identifier.contains("medication_\(medicationName)") }
                .map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    /// 同步所有用药提醒（从药品列表重建）
    func syncMedications(_ medications: [Medication]) {
        // 先清除所有用药提醒
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let medIds = requests
                .filter { $0.identifier.hasPrefix("medication_") }
                .map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: medIds)
        }

        // 重新创建
        for med in medications {
            scheduleMedicationReminder(
                medicationName: med.name,
                dose: med.dose,
                timeString: med.reminderTime
            )
        }
    }

    // MARK: - 复诊提醒

    /// 创建复诊提醒（就诊前一天提醒）
    func scheduleFollowUpReminder(visitRecord: VisitRecord) {
        guard let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: visitRecord.date) else { return }

        let content = UNMutableNotificationContent()
        content.title = "🏥 明天有就诊"
        content.body = "\(visitRecord.department) · \(visitRecord.hospital)"
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let identifier = "followup_\(visitRecord.id.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("复诊提醒创建失败: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 未服药提醒

    /// 如果过了提醒时间仍未确认服药，发送第二次提醒
    func scheduleMissedDoseReminder(medicationName: String, dose: String, delayMinutes: Int = 30) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ 别忘了吃药"
        content.body = "\(medicationName) · \(dose) 尚未确认服用"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(delayMinutes * 60), repeats: false)

        let identifier = "missed_\(medicationName)_\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}
