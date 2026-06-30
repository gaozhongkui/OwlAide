import SwiftUI
import SwiftData
import Combine

struct MedicationReminderView: View {
    @Query var medications: [Medication]
    @Environment(\.modelContext) private var modelContext
    @StateObject private var settings = AppSettings.shared

    var body: some View {
        VStack(spacing: 0) {
            Text("Medication Reminders")
                .font(AppTheme.titleFont)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.white)

            ScrollView {
                VStack(spacing: 16) {
                    // Today's Progress Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Today's Progress").font(AppTheme.bodyFont).foregroundColor(.gray)
                            Spacer()
                            let takenCount = medications.filter { $0.isTakenToday }.count
                            Text("\(takenCount)/\(medications.count)").font(AppTheme.captionFont).foregroundColor(AppTheme.teal)
                        }

                        if medications.isEmpty {
                            Text("No medications scheduled").font(AppTheme.bodyFont).foregroundColor(.gray).padding(.vertical, 10)
                        } else {
                            ForEach(medications) { med in
                                MedicationReminderRow(med: med)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 10)

                    // My Medbox
                    Text("My Medbox").font(AppTheme.bodyFont).foregroundColor(.gray).frame(maxWidth: .infinity, alignment: .leading).padding(.top)

                    VStack(spacing: 10) {
                        ForEach(medications) { med in
                            HStack {
                                Text("💊").font(.system(size: 26))
                                VStack(alignment: .leading) {
                                    Text(med.name).font(AppTheme.bodyFont)
                                    Text(med.dose).font(AppTheme.captionFont).foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
        }
        .background(settings.backgroundColor)
        .onAppear {
            // Ensure notification permissions and sync all medication reminders
            NotificationManager.shared.requestAuthorization()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationManager.shared.syncMedications(medications)
            }
        }
    }
}

struct MedicationReminderRow: View {
    @Bindable var med: Medication

    var body: some View {
        HStack(spacing: 12) {
            Text("Today").font(AppTheme.captionFont).foregroundColor(med.isTakenToday ? .gray : AppTheme.teal)

            VStack(alignment: .leading, spacing: 2) {
                Text(med.name)
                    .font(AppTheme.bodyFont)
                    .strikethrough(med.isTakenToday)
                    .foregroundColor(med.isTakenToday ? .gray : AppTheme.textMain)
                Text(med.dose).font(AppTheme.captionFont).foregroundColor(.gray)
            }

            Spacer()

            if med.isTakenToday {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppTheme.teal)
                    .font(.system(size: 28))
            } else {
                Button(action: {
                    withAnimation {
                        med.isTakenToday = true
                    }
                    TTSService.shared.speak("Confirmed taking \(med.name)")
                    // Cancel reminder
                    NotificationManager.shared.cancelMedicationReminder(medicationName: med.name)
                }) {
                    Text("Take Now")
                        .font(AppTheme.buttonFont)
                        .foregroundColor(AppTheme.teal)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(AppTheme.tealLight)
                        .cornerRadius(20)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
