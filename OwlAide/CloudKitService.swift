import Foundation
import Combine
import CloudKit

/// 封装 CloudKit 操作：保存记录、创建 CKShare、接受分享、拉取共享记录
/// 完全免费（CloudKit 免费额度足够家庭场景使用）
class CloudKitService: ObservableObject {
    static let shared = CloudKitService()

    private let container: CKContainer
    private let privateDB: CKDatabase
    private let sharedDB: CKDatabase

    @Published var sharedRecords: [SharedVisitRecord] = []
    @Published var isUploading = false

    init() {
        container = CKContainer(identifier: "iCloud.com.owl.aide.owlaide")
        privateDB = container.privateCloudDatabase
        sharedDB = container.sharedCloudDatabase
    }

    // MARK: - iCloud 账户状态

    func checkAccountStatus() async -> CKAccountStatus? {
        try? await container.accountStatus()
    }

    // MARK: - 保存就诊记录到 CloudKit 并创建 CKShare

    /// 分享就诊记录。如果提供家人 email 列表，会自动静默分享给他们（无需弹出面板）；
    /// 如果自动分享失败或无 email，返回 CKShare 供手动分享面板使用。
    func shareRecord(_ record: VisitRecord, recipientEmails: [String] = []) async throws -> CKShare {
        await MainActor.run { isUploading = true }
        defer { Task { @MainActor in isUploading = false } }

        // 1. 将 VisitRecord 转为 CKRecord
        let ckRecord = CKRecord(recordType: "VisitRecord", recordID: CKRecord.ID(recordName: record.id.uuidString))
        ckRecord["jsonData"] = record.toJSON()
        ckRecord["department"] = record.department
        ckRecord["hospital"] = record.hospital
        ckRecord["date"] = record.date

        // 2. 保存到私有数据库
        let savedRecord = try await privateDB.save(ckRecord)

        // 3. 创建 CKShare
        let share = CKShare(rootRecord: savedRecord)
        share[CKShare.SystemFieldKey.title] = "\(record.department)就诊报告 - \(formatDate(record.date))"
        share[CKShare.SystemFieldKey.shareType] = "com.owl.aide.report"

        // 4. 同时保存根记录和 share（参与者通过 UICloudSharingController 手动添加）
        let recordsToSave: [CKRecord] = [savedRecord, share]
        let modifyOp = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: nil)
        modifyOp.savePolicy = .changedKeys

        return try await withCheckedThrowingContinuation { continuation in
            modifyOp.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: share)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            privateDB.add(modifyOp)
        }
    }

    // MARK: - 接受家人分享

    func acceptShare(url: URL) async throws {
        let metadata = try await container.shareMetadata(for: url)

        let acceptOp = CKAcceptSharesOperation(shareMetadatas: [metadata])

        return try await withCheckedThrowingContinuation { continuation in
            acceptOp.acceptSharesResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            container.add(acceptOp)
        }
    }

    // MARK: - 拉取家人分享的记录

    func fetchSharedRecords() async {
        do {
            let query = CKQuery(recordType: "VisitRecord", predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

            let (results, _) = try await sharedDB.records(matching: query, desiredKeys: nil, resultsLimit: 50)

            var records: [SharedVisitRecord] = []
            for (_, result) in results {
                switch result {
                case .success(let ckRecord):
                    if let jsonData = ckRecord["jsonData"] as? String,
                       let visitRecord = VisitRecord.fromJSON(jsonData) {
                        records.append(SharedVisitRecord(
                            record: visitRecord,
                            creationDate: ckRecord.creationDate,
                            recordID: ckRecord.recordID
                        ))
                    }
                case .failure:
                    continue
                }
            }

            await MainActor.run {
                self.sharedRecords = records
            }
        } catch {
            print("拉取共享记录失败: \(error.localizedDescription)")
        }
    }

    // MARK: - 删除共享记录

    func deleteSharedRecord(_ recordID: CKRecord.ID) async throws {
        try await sharedDB.deleteRecord(withID: recordID)
        await fetchSharedRecords()
    }

    // MARK: - 辅助

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "M月d日"
        return f.string(from: date)
    }
}

/// 家人分享的就诊记录包装
struct SharedVisitRecord: Identifiable {
    let id = UUID()
    let record: VisitRecord
    let creationDate: Date?
    let recordID: CKRecord.ID
}
