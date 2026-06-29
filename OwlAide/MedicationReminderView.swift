import SwiftUI
import SwiftData

struct MedicationReminderView: View {
    @Query var medications: [Medication]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 0) {
            Text("用药提醒")
                .font(.system(size: 20, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.white)

            ScrollView {
                VStack(spacing: 16) {
                    // 今日提醒卡片
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("今日进度").font(.system(size: 14, weight: .bold)).foregroundColor(.gray)
                            Spacer()
                            let takenCount = medications.filter { $0.isTakenToday }.count
                            Text("\(takenCount)/\(medications.count)").font(.system(size: 12)).foregroundColor(AppTheme.teal)
                        }

                        if medications.isEmpty {
                            Text("暂无服药计划").font(.system(size: 14)).foregroundColor(.gray).padding(.vertical, 10)
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

                    // 补充说明
                    Text("我的药箱").font(.system(size: 14, weight: .bold)).foregroundColor(.gray).frame(maxWidth: .infinity, alignment: .leading).padding(.top)

                    VStack(spacing: 10) {
                        ForEach(medications) { med in
                            HStack {
                                Text("💊").font(.system(size: 20))
                                VStack(alignment: .leading) {
                                    Text(med.name).font(.system(size: 15, weight: .semibold))
                                    Text(med.dose).font(.system(size: 12)).foregroundColor(.gray)
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
        .background(AppTheme.background)
    }
}

struct MedicationReminderRow: View {
    @Bindable var med: Medication

    var body: some View {
        HStack(spacing: 12) {
            Text("今日").font(.system(size: 13, weight: .bold)).foregroundColor(med.isTakenToday ? .gray : AppTheme.teal)

            VStack(alignment: .leading, spacing: 2) {
                Text(med.name)
                    .font(.system(size: 15, weight: .semibold))
                    .strikethrough(med.isTakenToday)
                    .foregroundColor(med.isTakenToday ? .gray : AppTheme.textMain)
                Text(med.dose).font(.system(size: 12)).foregroundColor(.gray)
            }

            Spacer()

            if med.isTakenToday {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppTheme.teal)
                    .font(.system(size: 24))
            } else {
                Button(action: {
                    withAnimation {
                        med.isTakenToday = true
                    }
                }) {
                    Text("确认服用")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.teal)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.tealLight)
                        .cornerRadius(20)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
