import SwiftUI
import SwiftData

// MARK: - HomeView (主导航容器)
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VisitRecord.date, order: .reverse) private var records: [VisitRecord]

    var onPrepareClick: () -> Void = {}
    var onRecordClick: () -> Void = {}
    var onSummaryViewClick: (VisitRecord) -> Void = { _ in }

    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch selectedTab {
                case 0:
                    MainDashboardView(
                        records: records,
                        onPrepareClick: onPrepareClick,
                        onRecordClick: onRecordClick,
                        onSummaryViewClick: onSummaryViewClick
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
                TabBarItem(icon: "house.fill", label: "首页", isActive: selectedTab == 0) { selectedTab = 0 }
                TabBarItem(icon: "calendar", label: "就诊", isActive: selectedTab == 1) { selectedTab = 1 }
                TabBarItem(icon: "pills.fill", label: "用药", isActive: selectedTab == 2) { selectedTab = 2 }
                TabBarItem(icon: "person.2.fill", label: "家庭", isActive: selectedTab == 3) { selectedTab = 3 }
            }
            .padding(.top, 10)
            .padding(.bottom, 24)
            .background(Color.white)
            .overlay(Divider(), alignment: .top)
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

// MARK: - MainDashboardView (首页仪表盘)
struct MainDashboardView: View {
    let records: [VisitRecord]
    var onPrepareClick: () -> Void
    var onRecordClick: () -> Void
    var onSummaryViewClick: (VisitRecord) -> Void

    var body: some View {
        ZStack(alignment: .top) {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("早上好").font(.system(size: 14)).opacity(0.85)
                    Text("李奶奶").font(.system(size: 24, weight: .bold))
                    Text("今天是 \(formattedToday())").font(.system(size: 13)).opacity(0.75)
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
                        NextVisitCard(onPrepare: onPrepareClick)

                        Text("快捷功能")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.gray)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            QuickCard(icon: "mic.fill", iconColor: AppTheme.teal, bgColor: AppTheme.tealLight, title: "开始录音", desc: "就诊时使用", action: onRecordClick)
                            QuickCard(icon: "clipboard.fill", iconColor: AppTheme.warm, bgColor: AppTheme.warmLight, title: "准备问诊", desc: "记录症状问题", action: onPrepareClick)
                            QuickCard(icon: "doc.text.fill", iconColor: AppTheme.purple, bgColor: AppTheme.purpleLight, title: "上次摘要", desc: records.first?.department ?? "无记录", action: {
                                if let last = records.first { onSummaryViewClick(last) }
                            })
                            QuickCard(icon: "paperplane.fill", iconColor: AppTheme.orange, bgColor: AppTheme.orangeLight, title: "发给子女", desc: "分享最新报告", action: {})
                        }

                        Text("就诊历史")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.gray)

                        if records.isEmpty {
                            Text("暂无记录").font(.system(size: 14)).foregroundColor(.gray).padding()
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
    }

    private func formattedToday() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 EEEE"
        return f.string(from: Date())
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy年M月d日"
        return f.string(from: date)
    }
}
