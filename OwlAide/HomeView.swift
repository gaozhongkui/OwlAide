import SwiftUI
import SwiftData
import CloudKit

// MARK: - HomeView (主导航容器)
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VisitRecord.date, order: .reverse) private var records: [VisitRecord]
    @Query private var familyMembers: [FamilyMember]

    var onPrepareClick: () -> Void = {}
    var onRecordClick: () -> Void = {}
    var onSummaryViewClick: (VisitRecord) -> Void = { _ in }

    @State private var selectedTab = 0
    @State private var shareForRecord: VisitRecord?
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
        shareForRecord = record
        let emails = familyMembers.compactMap { $0.email.isEmpty ? nil : $0.email }
        Task {
            do {
                let share = try await CloudKitService.shared.shareRecord(record, recipientEmails: emails)
                await MainActor.run {
                    if emails.isEmpty {
                        // 无家人 email，弹出手动分享面板
                        self.cloudShare = share
                        self.showCloudSharing = true
                    }
                    // 有 email 时自动静默分享，无需弹面板
                }
            } catch {
                // CloudKit 不可用时回退到文本分享
                await MainActor.run {
                    shareViaText(record)
                }
            }
        }
    }

    private func shareViaText(_ record: VisitRecord) {
        let text = "【OwlAide 就诊报告】\n科室：\(record.department)\n建议：\(record.doctorAdvice)\n详细内容已同步至 OwlAide 家庭分享。"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(av, animated: true)
        }
    }
}

// MARK: - MainDashboardView (首页仪表盘)
struct MainDashboardView: View {
    let records: [VisitRecord]
    let familyMembers: [FamilyMember]
    var onPrepareClick: () -> Void
    var onRecordClick: () -> Void
    var onSummaryViewClick: (VisitRecord) -> Void
    var onFamilyTabClick: () -> Void
    var onShareRecord: (VisitRecord) -> Void = { _ in }

    var body: some View {
        ZStack(alignment: .top) {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("早上好").font(.system(size: 14)).opacity(0.85)
                            Text("李奶奶").font(.system(size: 24, weight: .bold))
                        }
                        Spacer()
                        // 紧急呼叫按钮
                        if let emergencyContact = familyMembers.first(where: { $0.isEmergencyContact }) {
                            Button(action: {
                                if let url = URL(string: "tel://\(emergencyContact.phoneNumber)") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "phone.fill.badge.plus")
                                        .font(.system(size: 20))
                                    Text("一键呼救").font(.system(size: 10, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(12)
                            }
                        }
                    }
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
                            QuickCard(icon: "icloud.fill", iconColor: AppTheme.orange, bgColor: AppTheme.orangeLight, title: "发给子女", desc: familyMembers.isEmpty ? "点击添加家人" : "用 iCloud 分享报告", action: {
                                if familyMembers.isEmpty {
                                    onFamilyTabClick()
                                } else if let last = records.first {
                                    onShareRecord(last)
                                } else {
                                    onFamilyTabClick()
                                }
                            })
                        }

                        // 家人动态
                        if !familyMembers.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("家人动态")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.gray)

                                HStack {
                                    Image(systemName: "checkmark.shield.fill")
                                        .foregroundColor(AppTheme.teal)
                                    Text("通过 iCloud 安全分享，家人用自己的 Apple ID 查看")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Button("查看") { onFamilyTabClick() }
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(AppTheme.teal)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                            }
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
