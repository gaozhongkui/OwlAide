import SwiftUI
import SwiftData

@main
struct OwlAideApp: App {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var healthKit = HealthKitManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(healthKit)
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
                .task {
                    // 初始化通知权限
                    NotificationManager.shared.requestAuthorization()
                    // 初始化 HealthKit（静默授权）
                    await healthKit.requestAuthorization()
                }
        }
        .modelContainer(for: [VisitRecord.self, Medication.self, FamilyMember.self])
    }
}
