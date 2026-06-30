import SwiftUI
import SwiftData
import CloudKit

struct SummaryView: View {
    var record: VisitRecord?
    var onBackToHome: () -> Void = {}

    @Query private var familyMembers: [FamilyMember]
    @StateObject private var audioManager = AudioManager()
    @State private var showCloudSharing = false
    @State private var cloudShare: CKShare?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("\(formatDate(record?.date ?? Date())) · \(record?.department ?? String(localized: "Unknown Dept"))")
                    .font(.system(size: 13))
                    .opacity(0.75)
                Text("Visit Summary")
                    .font(.system(size: 20, weight: .bold))
                Text("AI has organized the visit details for you")
                    .font(.system(size: 13))
                    .opacity(0.8)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(AppTheme.teal)

            ScrollView {
                VStack(spacing: 12) {
                    // Recording playback bar
                    if let audioPath = record?.audioPath {
                        AudioPlaybackRow(audioPath: audioPath, audioManager: audioManager)
                    }

                    // Doctor's instructions
                    if let advice = record?.doctorAdvice, !advice.isEmpty {
                        AdviceBox(advice: advice)
                    }

                    // Diagnosis
                    SummaryCard(icon: "stethoscope", iconColor: AppTheme.teal, bgColor: AppTheme.tealLight, title: String(localized: "Diagnosis")) {
                        SummaryBullet(text: record?.aiSummary ?? String(localized: "No summary available"), color: AppTheme.teal)
                    }

                    // Medication
                    SummaryCard(icon: "pill.fill", iconColor: AppTheme.warm, bgColor: AppTheme.warmLight, title: String(localized: "Medication")) {
                        VStack(alignment: .leading, spacing: 10) {
                            if let meds = record?.medications, !meds.isEmpty {
                                ForEach(meds) { med in
                                    SummaryBullet(text: "\(med.name) \(med.dose)", color: AppTheme.warm)
                                }
                            } else {
                                SummaryBullet(text: String(localized: "No new medication added"), color: AppTheme.warm)
                            }
                        }
                    }

                    // Follow-up
                    SummaryCard(icon: "calendar", iconColor: AppTheme.purple, bgColor: AppTheme.purpleLight, title: String(localized: "Follow-up")) {
                        SummaryBullet(text: String(localized: "Follow-up recommended in a month. Please bring this report for comparison."), color: AppTheme.purple)
                    }
                }
                .padding(16)
            }
            .background(AppTheme.background)

            // Bottom Actions
            HStack(spacing: 12) {
                Button(action: { shareViaCloudKit() }) {
                    Text("Share with Family").font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14).background(AppTheme.teal).cornerRadius(14)
                }
                Button(action: onBackToHome) {
                    Text("Home").font(.system(size: 15, weight: .semibold)).foregroundColor(AppTheme.teal)
                        .frame(maxWidth: .infinity).padding(.vertical, 14).background(AppTheme.tealLight).cornerRadius(14)
                }
            }
            .padding(16).background(Color.white)
        }
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

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func shareViaCloudKit() {
        guard let record = record else { return }
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
        let text = "\(title)\n\(deptLabel): \(record.department)\n\(adviceLabel): \(record.doctorAdvice)"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(av, animated: true)
        }
    }
}

// Subcomponents
struct AudioPlaybackRow: View {
    let audioPath: String
    @ObservedObject var audioManager: AudioManager

    var body: some View {
        HStack(spacing: 15) {
            Button(action: {
                if audioManager.isPlaying { audioManager.stopPlayback() }
                else {
                    let url = audioManager.getDocumentsDirectory().appendingPathComponent(audioPath)
                    audioManager.startPlayback(audioURL: url)
                }
            }) {
                Image(systemName: audioManager.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 44)).foregroundColor(AppTheme.teal)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(audioManager.isPlaying ? String(localized: "Playing recording...") : String(localized: "Play doctor's conversation")).font(.system(size: 13))
                Capsule().fill(Color.gray.opacity(0.1)).frame(height: 4)
                    .overlay(GeometryReader { g in
                        if audioManager.isPlaying { Capsule().fill(AppTheme.teal).frame(width: g.size.width * 0.6) }
                    }, alignment: .leading)
            }
        }
        .padding(12).background(Color.white).cornerRadius(12)
    }
}

struct AdviceBox: View {
    let advice: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("⚠️").font(.system(size: 20))
            Text("\(String(localized: "Doctor's Advice")): ").font(.system(size: 13, weight: .bold)).foregroundColor(AppTheme.warningText) +
            Text(advice).font(.system(size: 13)).foregroundColor(AppTheme.warningText)
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.orangeLight).cornerRadius(10)
    }
}
