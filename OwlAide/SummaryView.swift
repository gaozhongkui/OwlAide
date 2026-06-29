import SwiftUI
import SwiftData

struct SummaryView: View {
    var record: VisitRecord?
    var onBackToHome: () -> Void = {}

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
                    // Highlight Box
                    if let advice = record?.doctorAdvice, !advice.isEmpty {
                        HStack(alignment: .top, spacing: 10) {
                            Text("⚠️")
                                .font(.system(size: 20))

                            Text("医生叮嘱：")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(hex: "795548")) +
                            Text(advice)
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "795548"))
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: "FFF8E1"))
                        .cornerRadius(10)
                    }

                    // Diagnostic Card
                    SummaryCard(icon: "stethoscope", iconColor: AppTheme.teal, bgColor: AppTheme.tealLight, title: "诊断结论") {
                        VStack(alignment: .leading, spacing: 10) {
                            SummaryBullet(text: record?.aiSummary ?? "暂无结论", color: AppTheme.teal)
                        }
                    }

                    // Medication Card
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

                    // Follow-up Card
                    SummaryCard(icon: "calendar", iconColor: Color.purple, bgColor: Color.purple.opacity(0.1), title: "复诊安排") {
                        VStack(alignment: .leading, spacing: 10) {
                            SummaryBullet(text: "请遵循医生线下建议时间复诊", color: Color.purple)
                        }
                    }
                }
                .padding(16)
            }
            .background(AppTheme.background)

            // Bottom Actions
            HStack(spacing: 12) {
                Button(action: {
                    if let record = record { shareRecord(record) }
                }) {
                    Text("发给子女")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.teal)
                        .cornerRadius(14)
                }

                Button(action: onBackToHome) {
                    Text("返回首页")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.teal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.tealLight)
                        .cornerRadius(14)
                }
            }
            .padding(16)
            .background(Color.white)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    private func shareRecord(_ record: VisitRecord) {
        let text = "【OwlAide 就诊摘要】\n科室：\(record.department)\n日期：\(formatDate(record.date))\n医嘱：\(record.doctorAdvice)"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(av, animated: true)
        }
    }
}
