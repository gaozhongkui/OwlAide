import SwiftUI
import SwiftData
import CloudKit

@main
struct OwlAideApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    // 处理家人分享的 iCloud 链接
                    if url.absoluteString.contains("icloud.com/share") {
                        Task {
                            do {
                                try await CloudKitService.shared.acceptShare(url: url)
                            } catch {
                                print("接受分享失败: \(error.localizedDescription)")
                            }
                        }
                    }
                }
        }
        .modelContainer(for: [VisitRecord.self, Medication.self, FamilyMember.self])
    }
}
