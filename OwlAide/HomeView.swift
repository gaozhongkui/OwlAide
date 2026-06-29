import SwiftUI
import SwiftData

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
                if selectedTab == 0 {
                    MainDashboardView(
                        records: records,
                        onPrepareClick: onPrepareClick,
                        onRecordClick: onRecordClick,
                        onSummaryViewClick: onSummaryViewClick
                    )
                } else if selectedTab == 1 {
                    CalendarView()
                } else if selectedTab == 2 {
                    MedicationReminderView()
                } else {
                    FamilyView()
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

// --- Dashboard Subviews ---

struct NextVisitCard: View {
    var onPrepare: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("下次就诊").font(.system(size: 11, weight: .semibold)).foregroundColor(AppTheme.teal).tracking(0.5)
            VStack(alignment: .leading, spacing: 2) {
                Text("7月3日（周四）上午9:00").font(.system(size: 20, weight: .bold))
                Text("北京协和医院 · 心内科").font(.system(size: 14)).foregroundColor(AppTheme.textSub)
            }
            HStack(spacing: 8) {
                Button(action: onPrepare) {
                    Text("准备问诊").font(.system(size: 13, weight: .semibold)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 10).background(AppTheme.teal).cornerRadius(10)
                }
                Button(action: {}) {
                    Text("取消提醒").font(.system(size: 13, weight: .semibold)).foregroundColor(AppTheme.teal).frame(maxWidth: .infinity).padding(.vertical, 10).background(AppTheme.tealLight).cornerRadius(10)
                }
            }
        }
        .padding(16).background(AppTheme.cardWhite).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.tealLight, lineWidth: 1.5))
    }
}

struct QuickCard: View {
    let icon: String
    let iconColor: Color
    let bgColor: Color
    let title: String
    let desc: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(bgColor).frame(width: 36, height: 36)
                    Image(systemName: icon).foregroundColor(iconColor).font(.system(size: 18))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(AppTheme.textMain)
                    Text(desc).font(.system(size: 11)).foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(14).background(AppTheme.cardWhite).cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "f0f0f0"), lineWidth: 1.5))
        }
    }
}

struct HistoryItem: View {
    let date: String
    let title: String
    let isActive: Bool
    var body: some View {
        HStack(spacing: 12) {
            Circle().fill(isActive ? AppTheme.teal : Color.gray.opacity(0.3)).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(date).font(.system(size: 12)).foregroundColor(.gray)
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(AppTheme.textMain)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 16)).foregroundColor(Color.gray.opacity(0.3))
        }
        .padding(.horizontal, 14).padding(.vertical, 12).background(AppTheme.cardWhite).cornerRadius(12)
    }
}

struct TabBarItem: View {
    let icon: String
    let label: String
    let isActive: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 20))
                Text(label).font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isActive ? AppTheme.teal : Color.gray.opacity(0.4)).frame(maxWidth: .infinity)
        }
    }
}
