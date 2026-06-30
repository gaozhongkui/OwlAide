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
                Text("Family Sharing Center")
                    .font(.system(size: 22, weight: .bold))
                Text("Keep your children informed about your health")
                    .font(.system(size: 13))
                    .opacity(0.8)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(AppTheme.teal)

            ScrollView {
                VStack(spacing: 20) {
                    // iCloud Sharing Status Card
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Secure iCloud Sharing")
                                .font(.system(size: 15, weight: .bold))
                            Text("Share visit reports securely via encrypted Apple iCloud. Family members view with their own Apple ID; data never touches third-party servers.")
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

                    // Reports Shared by Family
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Reports Shared by Family").font(.system(size: 14, weight: .bold)).foregroundColor(.gray)
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
                                Text("No reports shared by family")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                                Text("Shared reports will appear here.\nTap the refresh button in the top right to check for updates.")
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

                    // Share My Reports
                    if !records.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Share My Reports").font(.system(size: 14, weight: .bold)).foregroundColor(.gray)
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

                    // Family Management
                    if familyMembers.isEmpty {
                        VStack(spacing: 15) {
                            Image(systemName: "person.2.badge.gearshape.fill")
                                .font(.system(size: 60))
                                .foregroundColor(AppTheme.tealLight)
                                .padding(.top, 40)
                            Text("No family members added yet")
                                .font(.system(size: 16, weight: .medium))
                            Text("After adding family, they can receive your visit reminders and AI summaries, and be contacted quickly in emergencies.")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    } else {
                        // Emergency Contacts
                        if familyMembers.contains(where: { $0.isEmergencyContact }) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Emergency Contacts").font(.system(size: 14, weight: .bold)).foregroundColor(.gray)
                                ForEach(familyMembers.filter { $0.isEmergencyContact }) { member in
                                    FamilyMemberRow(member: member, totalRecords: records.count)
                                }
                            }
                        }

                        // Other Members
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Family Members").font(.system(size: 14, weight: .bold)).foregroundColor(.gray)
                            ForEach(familyMembers.filter { !$0.isEmergencyContact }) { member in
                                FamilyMemberRow(member: member, totalRecords: records.count)
                            }
                        }
                    }

                    Button(action: { showingAddMember = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add New Family Member")
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
                    Section(header: Text("Basic Information")) {
                        TextField("Name", text: $newMemberName)
                        TextField("Relationship (e.g. Daughter)", text: $newMemberRelation)
                        Picker("Role", selection: $newMemberRole) {
                            ForEach(FamilyRole.allCases, id: \.self) { role in
                                Text(role.rawValue).tag(role)
                            }
                        }
                    }

                    Section(header: Text("Contact Info")) {
                        TextField("Phone Number", text: $newMemberPhone)
                            .keyboardType(.phonePad)
                        TextField("Apple ID Email (for automatic sharing)", text: $newMemberEmail)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        Toggle("Set as Emergency Contact", isOn: $isEmergencyContact)
                            .tint(AppTheme.teal)
                    }

                    Section(footer: Text("Fill in their Apple ID email to automatically share reports with them without manual steps.")) {
                        EmptyView()
                    }
                }
                .navigationTitle("Add Family Member")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingAddMember = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
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
                let share = try await CloudKitService.shared.shareRecord(record)
                await MainActor.run {
                    self.cloudShare = share
                    self.showCloudSharing = true
                }
            } catch {
                print("Sharing failed: \(error.localizedDescription)")
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
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

                Text("Synced \(member.syncCount) visit summaries")
                    .font(AppTheme.captionFont)
                    .foregroundColor(.gray)

                if let lastDate = member.lastSyncDate {
                    Text("Last synced: \(relativeTime(from: lastDate))")
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
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        if interval < 259200 { return "\(Int(interval / 86400))d ago" }
        let f = DateFormatter()
        f.dateFormat = "MMM dd"
        return f.string(from: date)
    }
}
