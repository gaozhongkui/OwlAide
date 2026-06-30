import Foundation
import Combine
import CloudKit

/// Wraps CloudKit operations: saving records, creating CKShare, accepting shares, and fetching shared records.
/// Fully free (CloudKit free tier is sufficient for family scenarios).
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

    // MARK: - iCloud Account Status

    func checkAccountStatus() async -> CKAccountStatus? {
        try? await container.accountStatus()
    }

    // MARK: - Save Visit Record to CloudKit and Create CKShare

    /// Shares a visit record, returning a CKShare for UICloudSharingController.
    func shareRecord(_ record: VisitRecord) async throws -> CKShare {
        await MainActor.run { isUploading = true }
        defer { Task { @MainActor in isUploading = false } }

        // 1. Convert VisitRecord to CKRecord
        let ckRecord = CKRecord(recordType: "VisitRecord", recordID: CKRecord.ID(recordName: record.id.uuidString))
        ckRecord["jsonData"] = record.toJSON()
        ckRecord["department"] = record.department
        ckRecord["hospital"] = record.hospital
        ckRecord["date"] = record.date

        // 2. Save to private database
        let savedRecord = try await privateDB.save(ckRecord)

        // 3. Create CKShare
        let share = CKShare(rootRecord: savedRecord)
        share[CKShare.SystemFieldKey.title] = "\(record.department) Visit Report - \(formatDate(record.date))"
        share[CKShare.SystemFieldKey.shareType] = "com.owl.aide.report"

        // 4. Save both the root record and the share (participants added via UICloudSharingController)
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

    // MARK: - Accept Family Share

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

    // MARK: - Fetch Records Shared by Family

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
            print("Failed to fetch shared records: \(error.localizedDescription)")
        }
    }

    // MARK: - Delete Shared Record

    func deleteSharedRecord(_ recordID: CKRecord.ID) async throws {
        try await sharedDB.deleteRecord(withID: recordID)
        await fetchSharedRecords()
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}

/// Wrapper for a visit record shared by a family member.
struct SharedVisitRecord: Identifiable {
    let id = UUID()
    let record: VisitRecord
    let creationDate: Date?
    let recordID: CKRecord.ID
}
