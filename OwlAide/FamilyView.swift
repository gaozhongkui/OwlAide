import SwiftUI
import SwiftData
import CloudKit

struct FamilyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FamilyMember.name) private var familyMembers: [FamilyMember]
    @Query private var records: [VisitRecord]

    @State private var showingAddMember = false
    @State private var newMemberName = ""
    @State private var newMemberRelation = ""
    @State private var newMemberRole: FamilyRole = .child
    @State private var newMemberPhone = ""
    @State private var newMemberEmail = ""
    @State private var isEmergencyContact = false

    @StateObject private var cloudKitService = CloudKitService.shared
    @State private var showCloudSharing = false
    @State private var cloudShare: CKShare?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("家庭共享中心")
                    .font(.system(size: 22, weight: .bold))
                Text("让子女随时了解您的健康动态")
                    .font(.system(size: 13))
                    .opacity(0.8)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(AppTheme.teal)

            ScrollView {
                VStack(spacing: 20) {
                    // iCloud 共享状态卡片
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("iCloud 安全分享")
                                .font(.system(size: 15, weight: .bold))
                            Text("通过 Apple iCloud 加密分享就诊报告，子女用自己的 Apple ID 查看，数据不经过第三方服务器。")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.teal)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.03), radius: 5)

                    // 家人分享的报告
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("家人分享的报告").font(.system(size: 14, weight: .bold)).foregroundColor(.gray)
                            Spacer()
                            Button(action: {
                                Task { await cloudKitService.fetchSharedRecords() }
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.teal)
                            }
                        }

                        if cloudKitService.sharedRecords.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "tray")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray.opacity(0.5))
                                Text("暂无家人分享的报告")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                                Text("家人分享后，报告会出现在这里。\n您可以点击右上角刷新按钮查看最新分享。")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        } else {
                            ForEach(cloudKitService.sharedRecords) { shared in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(shared.record.department) · \(shared.record.hospital)")
                                            .font(.system(size: 14, weight: .semibold))
                                        if let date = shared.creationDate {
                                            Text(formatDate(date))
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray.opacity(0.4))
                                }
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)

                    // 分享我的报告
                    if !records.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("分享我的报告").font(.system(size: 14, weight: .bold)).foregroundColor(.gray)
                            ForEach(records.prefix(3)) { record in
                                Button(action: {
                                    shareRecord(record)
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\(formatDate(record.date)) · \(record.department)")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(AppTheme.textMain)
                                            Text(record.hospital)
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 16))
                                            .foregroundColor(AppTheme.teal)
                                    }
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                    }

                    // 家庭成员管理
                    if familyMembers.isEmpty {
                        VStack(spacing: 15) {
                            Image(systemName: "person.2.badge.gearshape.fill")
                                .font(.system(size: 60))
                                .foregroundColor(AppTheme.tealLight)
                                .padding(.top, 40)
                            Text("还没有绑定家人")
                                .font(.system(size: 16, weight: .medium))
                            Text("添加家人后，他们可以收到您的就诊提醒和 AI 摘要，在紧急情况下也能快速联系。")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    } else {
                        // 紧急联系人
                        if familyMembers.contains(where: { $0.isEmergencyContact }) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("紧急联系人").font(.system(size: 14, weight: .bold)).foregroundColor(.gray)
                                ForEach(familyMembers.filter { $0.isEmergencyContact }) { member in
                                    FamilyMemberRow(member: member, totalRecords: records.count)
                                }
                            }
                        }

                        // 其他成员
                        VStack(alignment: .leading, spacing: 10) {
                            Text("家庭成员").font(.system(size: 14, weight: .bold)).foregroundColor(.gray)
                            ForEach(familyMembers.filter { !$0.isEmergencyContact }) { member in
                                FamilyMemberRow(member: member, totalRecords: records.count)
                            }
                        }
                    }

                    Button(action: { showingAddMember = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("添加新的家人")
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.teal)
                        .cornerRadius(14)
                        .shadow(color: AppTheme.teal.opacity(0.3), radius: 8, y: 4)
                    }
                    .padding(.top, 10)
                }
                .padding()
            }
        }
        .background(AppTheme.background)
        .sheet(isPresented: $showingAddMember) {
            NavigationStack {
                Form {
                    Section(header: Text("基本信息")) {
                        TextField("姓名", text: $newMemberName)
                        TextField("关系 (如: 大女儿)", text: $newMemberRelation)
                        Picker("成员角色", selection: $newMemberRole) {
                            ForEach(FamilyRole.allCases, id: \.self) { role in
                                Text(role.rawValue).tag(role)
                            }
                        }
                    }

                    Section(header: Text("联系方式")) {
                        TextField("手机号", text: $newMemberPhone)
                            .keyboardType(.phonePad)
                        TextField("Apple ID 邮箱（用于自动分享报告）", text: $newMemberEmail)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        Toggle("设为紧急联系人", isOn: $isEmergencyContact)
                            .tint(AppTheme.teal)
                    }

                    Section(footer: Text("填写家人的 Apple ID 邮箱后，分享报告时将自动发送给他们，无需手动操作。")) {
                        EmptyView()
                    }
                }
                .navigationTitle("添加家人")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") { showingAddMember = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("添加") {
                            addMember()
                            showingAddMember = false
                        }
                        .disabled(newMemberName.isEmpty)
                    }
                }
            }
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
        .task {
            await cloudKitService.fetchSharedRecords()
        }
    }

    private func addMember() {
        let newMember = FamilyMember(
            name: newMemberName,
            relation: newMemberRelation,
            role: newMemberRole,
            phoneNumber: newMemberPhone,
            email: newMemberEmail,
            isEmergency: isEmergencyContact
        )
        newMember.syncCount = records.count
        modelContext.insert(newMember)

        newMemberName = ""
        newMemberRelation = ""
        newMemberPhone = ""
        newMemberEmail = ""
        isEmergencyContact = false
    }

    private func shareRecord(_ record: VisitRecord) {
        let emails = familyMembers.compactMap { $0.email.isEmpty ? nil : $0.email }
        Task {
            do {
                let share = try await CloudKitService.shared.shareRecord(record, recipientEmails: emails)
                await MainActor.run {
                    self.cloudShare = share
                    self.showCloudSharing = true
                }
            } catch {
                print("分享失败: \(error.localizedDescription)")
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "M月d日"
        return f.string(from: date)
    }
}

struct FamilyMemberRow: View {
    let member: FamilyMember
    let totalRecords: Int

    var body: some View {
        HStack(spacing: 15) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 54))
                    .foregroundColor(AppTheme.teal.opacity(0.8))

                if member.isEmergencyContact {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .background(Color.white.clipShape(Circle()))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(member.name).font(AppTheme.bodyFont)
                    Text(member.relation)
                        .font(AppTheme.captionFont)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.tealLight)
                        .foregroundColor(AppTheme.teal)
                        .cornerRadius(4)
                }

                if !member.email.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        Text(member.email)
                            .font(AppTheme.captionFont)
                            .foregroundColor(.gray)
                    }
                }

                Text("已同步 \(member.syncCount) 条就诊摘要")
                    .font(AppTheme.captionFont)
                    .foregroundColor(.gray)

                if let lastDate = member.lastSyncDate {
                    Text("最近同步: \(relativeTime(from: lastDate))")
                        .font(.system(size: 11))
                        .foregroundColor(.gray.opacity(0.7))
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
    }

    private func relativeTime(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "刚刚" }
        if interval < 3600 { return "\(Int(interval / 60)) 分钟前" }
        if interval < 86400 { return "\(Int(interval / 3600)) 小时前" }
        if interval < 259200 { return "\(Int(interval / 86400)) 天前" }
        let f = DateFormatter()
        f.dateFormat = "MM月dd日"
        return f.string(from: date)
    }
}
