import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query(sort: \VisitRecord.date) var records: [VisitRecord]

    var body: some View {
        VStack(spacing: 0) {
            Text("就诊计划")
                .font(.system(size: 20, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.white)

            ScrollView {
                VStack(spacing: 16) {
                    // 模拟一个待就诊卡片
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("待就诊")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppTheme.teal)
                                .cornerRadius(4)
                            Spacer()
                            Text("7月3日 09:00").font(.system(size: 14)).foregroundColor(.gray)
                        }

                        Text("心内科定期复查").font(.system(size: 18, weight: .bold))
                        Text("北京协和医院 · 东院区").font(.system(size: 14)).foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 10)

                    Text("历史记录").font(.system(size: 14, weight: .bold)).foregroundColor(.gray).frame(maxWidth: .infinity, alignment: .leading).padding(.top)

                    ForEach(records) { record in
                        HistoryItem(date: "\(formatDate(record.date)) · \(record.department)", title: record.hospital, isActive: false)
                    }
                }
                .padding()
            }
        }
        .background(AppTheme.background)
    }

    func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MM月dd日"
        return f.string(from: date)
    }
}
