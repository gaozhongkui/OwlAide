import SwiftUI
import SwiftData

struct MedicationReminderView: View {
    @Query var medications: [Medication]

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
                        Text("今日剩余").font(.system(size: 14, weight: .bold)).foregroundColor(.gray)

                        MedicationReminderRow(time: "08:00", name: "苯磺酸氨氯地平片", dose: "5mg", status: .taken)
                        MedicationReminderRow(time: "12:00", name: "阿托伐他汀钙片", dose: "20mg", status: .pending)
                        MedicationReminderRow(time: "20:00", name: "塞来昔布胶囊", dose: "200mg", status: .pending)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 10)

                    // 全部药品
                    Text("我的药箱").font(.system(size: 14, weight: .bold)).foregroundColor(.gray).frame(maxWidth: .infinity, alignment: .leading).padding(.top)

                    if medications.isEmpty {
                        Text("暂无药品记录，请在问诊准备中添加").font(.system(size: 14)).foregroundColor(.gray).padding()
                    } else {
                        ForEach(medications) { med in
                            HStack {
                                Text("💊").font(.system(size: 24))
                                VStack(alignment: .leading) {
                                    Text(med.name).font(.system(size: 16, weight: .semibold))
                                    Text(med.dose).font(.system(size: 13)).foregroundColor(.gray)
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

enum MedicationStatus {
    case taken, pending
}

struct MedicationReminderRow: View {
    let time: String
    let name: String
    let dose: String
    let status: MedicationStatus

    var body: some View {
        HStack(spacing: 12) {
            Text(time).font(.system(size: 14, weight: .bold)).foregroundColor(status == .taken ? .gray : AppTheme.teal)

            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.system(size: 15, weight: .semibold)).strikethrough(status == .taken)
                Text(dose).font(.system(size: 12)).foregroundColor(.gray)
            }

            Spacer()

            if status == .taken {
                Image(systemName: "checkmark.circle.fill").foregroundColor(AppTheme.teal)
            } else {
                Button(action: {}) {
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
    }
}
