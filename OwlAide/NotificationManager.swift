import UserNotifications
import Foundation
import Combine

/// Local notification management: Medication reminders and follow-up alerts.
/// Fully local, no server required, free to use.
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false

    // MARK: - Permissions

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
            }
        }
    }

    // MARK: - Medication Reminders

    /// Schedule a daily reminder for a specific medication.
    func scheduleMedicationReminder(medicationName: String, dose: String, timeString: String) {
        let parts = timeString.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return }

        let content = UNMutableNotificationContent()
        content.title = "💊 Time for Medication"
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
                print("Failed to schedule medication reminder: \(error.localizedDescription)")
            }
        }
    }

    /// Cancel all reminders for a specific medication.
    func cancelMedicationReminder(medicationName: String) {
        // Remove based on name pattern
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests
                .filter { $0.identifier.contains("medication_\(medicationName)") }
                .map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    /// Sync all medication reminders (rebuild from medication list).
    func syncMedications(_ medications: [Medication]) {
        // Clear all medication reminders first
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let medIds = requests
                .filter { $0.identifier.hasPrefix("medication_") }
                .map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: medIds)
        }

        // Recreate
        for med in medications {
            scheduleMedicationReminder(
                medicationName: med.name,
                dose: med.dose,
                timeString: med.reminderTime
            )
        }
    }

    // MARK: - Follow-up Reminders

    /// Create a follow-up reminder (the day before the visit).
    func scheduleFollowUpReminder(visitRecord: VisitRecord) {
        guard let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: visitRecord.date) else { return }

        let content = UNMutableNotificationContent()
        content.title = "🏥 Upcoming Visit Tomorrow"
        content.body = "\(visitRecord.department) · \(visitRecord.hospital)"
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let identifier = "followup_\(visitRecord.id.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule follow-up reminder: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Missed Dose Reminders

    /// Send a second reminder if medication hasn't been confirmed after the scheduled time.
    func scheduleMissedDoseReminder(medicationName: String, dose: String, delayMinutes: Int = 30) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Don't forget your meds"
        content.body = "\(medicationName) · \(dose) has not been confirmed"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(delayMinutes * 60), repeats: false)

        let identifier = "missed_\(medicationName)_\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}
