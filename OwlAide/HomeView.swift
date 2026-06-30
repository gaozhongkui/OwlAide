import SwiftUI
import SwiftData
import CloudKit
import Foundation

// MARK: - HomeView (Main Navigation Container)
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VisitRecord.date, order: .reverse) private var records: [VisitRecord]
    @Query private var familyMembers: [FamilyMember]

    var onPrepareClick: () -> Void = {}
    var onRecordClick: () -> Void = {}
    var onSummaryViewClick: (VisitRecord) -> Void = { _ in }

    @State private var selectedTab = 0
    @State private var cloudShare: CKShare?
    @State private var showCloudSharing = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch selectedTab {
                case 0:
                    MainDashboardView(
                        records: records,
                        familyMembers: familyMembers,
                        onPrepareClick: onPrepareClick,
                        onRecordClick: onRecordClick,
                        onSummaryViewClick: onSummaryViewClick,
                        onFamilyTabClick: { selectedTab = 3 },
                        onShareRecord: { record in shareViaCloudKit(record) }
                    )
                case 1:
                    CalendarView()
                case 2:
                    MedicationReminderView()
                case 3:
                    FamilyView()
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Tab Bar
            HStack(spacing: 0) {
                TabBarItem(icon: "house.fill", label: String(localized: "Home"), isActive: selectedTab == 0) { selectedTab = 0 }
                TabBarItem(icon: "calendar", label: String(localized: "Visits"), isActive: selectedTab == 1) { selectedTab = 1 }
                TabBarItem(icon: "pills.fill", label: String(localized: "Meds"), isActive: selectedTab == 2) { selectedTab = 2 }
                TabBarItem(icon: "person.2.fill", label: String(localized: "Family"), isActive: selectedTab == 3) { selectedTab = 3 }
            }
            .padding(.top, 10)
            .padding(.bottom, 24)
            .background(Color.white)
            .overlay(Divider(), alignment: .top)
        }
        .edgesIgnoringSafeArea(.bottom)
        .sheet(isPresented: $showCloudSharing) {
            if let share = cloudShare {
                CloudSharingView(
                    container: CKContainer(identifier: "iCloud.com.owl.aide.owlaide"),
                    share: share,
                    onDismiss: { showCloudSharing = false }
                )
            }
        }
    }

    private func shareViaCloudKit(_ record: VisitRecord) {
        Task {
            do {
                let share = try await CloudKitService.shared.shareRecord(record)
                await MainActor.run {
                    self.cloudShare = share
                    self.showCloudSharing = true
                }
            } catch {
                await MainActor.run {
                    shareViaText(record)
                }
            }
        }
    }

    private func shareViaText(_ record: VisitRecord) {
        let title = String(localized: "[OwlAide Visit Report]")
        let deptLabel = String(localized: "Department")
        let adviceLabel = String(localized: "Advice")
        let footer = String(localized: "Details synced to OwlAide Family Share.")

        let text = "\(title)\n\(deptLabel): \(record.department)\n\(adviceLabel): \(record.doctorAdvice)\n\(footer)"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(av, animated: true)
        }
    }
}

// MARK: - MainDashboardView (Dashboard)
struct MainDashboardView: View {
    let records: [VisitRecord]
    let familyMembers: [FamilyMember]
    var onPrepareClick: () -> Void
    var onRecordClick: () -> Void
    var onSummaryViewClick: (VisitRecord) -> Void
    var onFamilyTabClick: () -> Void
    var onShareRecord: (VisitRecord) -> Void = { _ in }

    @StateObject private var healthKit = HealthKitManager.shared
    @StateObject private var settings = AppSettings.shared
    @State private var showSettings = false

    var body: some View {
        ZStack(alignment: .top) {
            settings.backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Good Morning").font(AppTheme.captionFont).opacity(0.85)
                            Text(settings.userName.isEmpty ? String(localized: "Hello") : settings.userName)
                                .font(AppTheme.titleFont)
                        }
                        Spacer()
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        if let emergencyContact = familyMembers.first(where: { $0.isEmergencyContact }) {
                            Button(action: {
                                Task {
                                    let msg = await LocationService.shared.emergencyMessage()
                                    if let url = URL(string: "tel://\(emergencyContact.phoneNumber)") {
                                        await MainActor.run { UIApplication.shared.open(url) }
                                    }
                                    await MainActor.run {
                                        let av = UIActivityViewController(activityItems: [msg], applicationActivities: nil)
                                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                           let rootVC = windowScene.windows.first?.rootViewController {
                                            rootVC.present(av, animated: true)
                                        }
                                    }
                                }
                                TTSService.shared.speak(String(localized: "Calling emergency contact and sending location"))
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "phone.fill.badge.plus")
                                        .font(.system(size: 20))
                                    Text("SOS").font(AppTheme.captionFont)
                                }
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(12)
                            }
                        }
                    }
                    Text("Today is \(formattedToday())").font(AppTheme.captionFont).opacity(0.75)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 28)
                .background(
                    LinearGradient(gradient: Gradient(colors: [AppTheme.teal, Color(hex: "2AA99B")]), startPoint: .topLeading, endPoint: .bottomTrailing)
                )

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if healthKit.isAuthorized {
                            HealthDataCard(healthKit: healthKit)
                        }

                        NextVisitCard(onPrepare: onPrepareClick)

                        Text("Quick Actions")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(.gray)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            QuickCard(icon: "mic.fill", iconColor: AppTheme.teal, bgColor: AppTheme.tealLight, title: String(localized: "Record"), desc: String(localized: "Use during visit"), action: {
                                TTSService.shared.speak(String(localized: "Starting recording"))
                                onRecordClick()
                            })
                            QuickCard(icon: "clipboard.fill", iconColor: AppTheme.warm, bgColor: AppTheme.warmLight, title: String(localized: "Prepare"), desc: String(localized: "Note symptoms"), action: {
                                TTSService.shared.speak(String(localized: "Preparing for visit"))
                                onPrepareClick()
                            })
                            QuickCard(icon: "doc.text.fill", iconColor: AppTheme.purple, bgColor: AppTheme.purpleLight, title: String(localized: "Last Summary"), desc: records.first?.department ?? String(localized: "No records"), action: {
                                if let last = records.first {
                                    TTSService.shared.speak(String(localized: "Viewing visit summary"))
                                    onSummaryViewClick(last)
                                }
                            })
                            QuickCard(icon: "icloud.fill", iconColor: AppTheme.orange, bgColor: AppTheme.orangeLight, title: String(localized: "Share"), desc: familyMembers.isEmpty ? String(localized: "Add family") : String(localized: "Share via iCloud"), action: {
                                if familyMembers.isEmpty {
                                    onFamilyTabClick()
                                } else if let last = records.first {
                                    TTSService.shared.speak(String(localized: "Sharing report with family"))
                                    onShareRecord(last)
                                } else {
                                    onFamilyTabClick()
                                }
                            })
                        }

                        if !familyMembers.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Family Activity")
                                    .font(AppTheme.bodyFont)
                                    .foregroundColor(.gray)

                                HStack {
                                    Image(systemName: "checkmark.shield.fill")
                                        .foregroundColor(AppTheme.teal)
                                    Text("Secure sharing via iCloud. Family members view with their own Apple ID.")
                                        .font(AppTheme.captionFont)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Button(String(localized: "View")) { onFamilyTabClick() }
                                        .font(AppTheme.buttonFont)
                                        .foregroundColor(AppTheme.teal)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                            }
                        }

                        Text("History")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(.gray)

                        if records.isEmpty {
                            Text("No records").font(AppTheme.bodyFont).foregroundColor(.gray).padding()
                        } else {
                            ForEach(records) { record in
                                HistoryItem(date: "\(formatDate(record.date))", title: record.hospital, isActive: record == records.first)
                                    .onTapGesture { onSummaryViewClick(record) }
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .task {
            if healthKit.isAuthorized {
                await healthKit.fetchLatestBloodPressure()
                await healthKit.fetchHeartRate()
                await healthKit.fetchStepCount()
            }
        }
    }

    private func formattedToday() -> String {
        let f = DateFormatter()
        f.locale = Locale.current
        f.setLocalizedDateFormatFromTemplate("MMMMdEEEE")
        return f.string(from: Date())
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}

// MARK: - Health Data Card

struct HealthDataCard: View {
    @ObservedObject var healthKit: HealthKitManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Health Data").font(AppTheme.captionFont).foregroundColor(AppTheme.teal)
                Spacer()
                Image(systemName: "heart.fill").font(.system(size: 14)).foregroundColor(AppTheme.warm)
            }

            HStack(spacing: 20) {
                HealthDataItem(
                    icon: "drop.fill",
                    color: AppTheme.warm,
                    label: String(localized: "BP"),
                    value: bloodPressureText,
                    unit: "mmHg"
                )

                Divider().frame(height: 40)

                HealthDataItem(
                    icon: "heart.fill",
                    color: .red,
                    label: String(localized: "HR"),
                    value: heartRateText,
                    unit: "bpm"
                )

                Divider().frame(height: 40)

                HealthDataItem(
                    icon: "figure.walk",
                    color: AppTheme.teal,
                    label: String(localized: "Steps"),
                    value: stepCountText,
                    unit: String(localized: "steps")
                )
            }
        }
        .padding(16)
        .background(AppTheme.cardWhite)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.tealLight, lineWidth: 1.5))
    }

    private var bloodPressureText: String {
        if let sys = healthKit.systolicBP, let dia = healthKit.diastolicBP {
            return "\(Int(sys))/\(Int(dia))"
        }
        return "--/--"
    }

    private var heartRateText: String {
        if let hr = healthKit.heartRate {
            return "\(Int(hr))"
        }
        return "--"
    }

    private var stepCountText: String {
        if let steps = healthKit.stepCount {
            return steps > 1000 ? "\(steps / 1000)k" : "\(steps)"
        }
        return "--"
    }
}

struct HealthDataItem: View {
    let icon: String
    let color: Color
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            Text(label)
                .font(AppTheme.captionFont)
                .foregroundColor(.gray)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.textMain)
                Text(unit)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
