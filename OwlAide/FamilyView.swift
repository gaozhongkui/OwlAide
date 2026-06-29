import SwiftUI
import SwiftData

struct FamilyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FamilyMember.name) private var familyMembers: [FamilyMember]
    @Query private var records: [VisitRecord]

    @State private var showingAddMember = false
    @State private var newMemberName = ""
    @State private var newMemberRelation = ""
    @State private var newMemberRole: FamilyRole = .child
    @State private var newMemberPhone = ""
    @State private var isEmergencyContact = false

    var body: some View {
        VStack(spacing: 0) {
            // Header inspired by prototype
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
                    // Sync Status Card
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("自动同步已开启")
                                .font(.system(size: 15, weight: .bold))
                            Text("您的就诊摘要、用药记录将自动分享给家人")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Toggle("", isOn: .constant(true)).labelsHidden()
                            .tint(AppTheme.teal)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.03), radius: 5)

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
                        // Emergency Contact Section
                        if familyMembers.contains(where: { $0.isEmergencyContact }) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("紧急联系人").font(.system(size: 14, weight: .bold)).foregroundColor(.gray)
                                ForEach(familyMembers.filter { $0.isEmergencyContact }) { member in
                                    FamilyMemberRow(member: member, totalRecords: records.count)
                                }
                            }
                        }

                        // Other Members
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
                        Toggle("设为紧急联系人", isOn: $isEmergencyContact)
                            .tint(AppTheme.teal)
                    }

                    Section(footer: Text("设为紧急联系人后，将在首页显示该成员的快捷通话按钮。")) {
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
    }

    private func addMember() {
        let newMember = FamilyMember(
            name: newMemberName,
            relation: newMemberRelation,
            role: newMemberRole,
            phoneNumber: newMemberPhone,
            isEmergency: isEmergencyContact
        )
        newMember.syncCount = records.count
        modelContext.insert(newMember)

        // Reset form
        newMemberName = ""
        newMemberRelation = ""
        newMemberPhone = ""
        isEmergencyContact = false
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
                    Text(member.name).font(.system(size: 17, weight: .bold))
                    Text(member.relation)
                        .font(.system(size: 12))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.tealLight)
                        .foregroundColor(AppTheme.teal)
                        .cornerRadius(4)
                }

                Text("已同步 \(member.syncCount) 条就诊摘要")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)

                if let lastDate = member.lastSyncDate {
                    Text("最近查看: \(formatDate(lastDate))")
                        .font(.system(size: 11))
                        .foregroundColor(.gray.opacity(0.7))
                }
            }

            Spacer()

            if !member.phoneNumber.isEmpty {
                Button(action: {
                    if let url = URL(string: "tel://\(member.phoneNumber)") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(member.isEmergencyContact ? Color.red : AppTheme.teal)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
