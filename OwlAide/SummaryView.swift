import SwiftUI
import SwiftData

struct SummaryView: View {
    var record: VisitRecord?
    var onBackToHome: () -> Void = {}

    @StateObject private var audioManager = AudioManager()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("\(formatDate(record?.date ?? Date())) · \(record?.department ?? "未知科室")")
                    .font(.system(size: 13))
                    .opacity(0.75)
                Text("就诊摘要")
                    .font(.system(size: 20, weight: .bold))
                Text("AI 已为您整理好就诊内容")
                    .font(.system(size: 13))
                    .opacity(0.8)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(AppTheme.teal)

            ScrollView {
                VStack(spacing: 12) {
                    // 录音回放条
                    if let audioPath = record?.audioPath {
                        AudioPlaybackRow(audioPath: audioPath, audioManager: audioManager)
                    }

                    // 医生叮嘱 (HTML sum-highlight)
                    if let advice = record?.doctorAdvice, !advice.isEmpty {
                        AdviceBox(advice: advice)
                    }

                    // 诊断结论 (HTML Diagnostic Card)
                    SummaryCard(icon: "stethoscope", iconColor: AppTheme.teal, bgColor: AppTheme.tealLight, title: "诊断结论") {
                        SummaryBullet(text: record?.aiSummary ?? "暂无结论", color: AppTheme.teal)
                    }

                    // 用药安排 (HTML Medication Card)
                    SummaryCard(icon: "pill.fill", iconColor: AppTheme.warm, bgColor: AppTheme.warmLight, title: "用药安排") {
                        VStack(alignment: .leading, spacing: 10) {
                            if let meds = record?.medications, !meds.isEmpty {
                                ForEach(meds) { med in
                                    SummaryBullet(text: "\(med.name) \(med.dose)", color: AppTheme.warm)
                                }
                            } else {
                                SummaryBullet(text: "本次无新增药物", color: AppTheme.warm)
                            }
                        }
                    }

                    // 复诊安排 (补全 HTML Follow-up Card)
                    SummaryCard(icon: "calendar", iconColor: AppTheme.purple, bgColor: AppTheme.purpleLight, title: "复诊安排") {
                        SummaryBullet(text: "建议一个月后复查（7月15日前）\n届时请带上此次检查报告对比。", color: AppTheme.purple)
                    }
                }
                .padding(16)
            }
            .background(AppTheme.background)

            // Bottom Actions
            HStack(spacing: 12) {
                Button(action: { if let r = record { shareRecord(r) } }) {
                    Text("发给子女").font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14).background(AppTheme.teal).cornerRadius(14)
                }
                Button(action: onBackToHome) {
                    Text("返回首页").font(.system(size: 15, weight: .semibold)).foregroundColor(AppTheme.teal)
                        .frame(maxWidth: .infinity).padding(.vertical, 14).background(AppTheme.tealLight).cornerRadius(14)
                }
            }
            .padding(16).background(Color.white)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    private func shareRecord(_ record: VisitRecord) {
        let text = "【OwlAide 就诊报告】\n科室：\(record.department)\n建议：\(record.doctorAdvice)"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(av, animated: true)
        }
    }
}

// 子组件
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
                Text(audioManager.isPlaying ? "正在播放就诊原音..." : "回放医生现场对话").font(.system(size: 13))
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
            Text("医生叮嘱：").font(.system(size: 13, weight: .bold)).foregroundColor(AppTheme.warningText) +
            Text(advice).font(.system(size: 13)).foregroundColor(AppTheme.warningText)
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.orangeLight).cornerRadius(10)
    }
}
