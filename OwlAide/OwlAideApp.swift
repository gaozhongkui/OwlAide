import SwiftUI
import SwiftData

@main
struct OwlAideApp: App {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var healthKit = HealthKitManager.shared
    @StateObject private var subscription = SubscriptionManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(healthKit)
                .onOpenURL { url in
                    // Handle iCloud share links from family
                    if url.absoluteString.contains("icloud.com/share") {
                        Task {
                            do {
                                try await CloudKitService.shared.acceptShare(url: url)
                            } catch {
                                print("Failed to accept share: \(error.localizedDescription)")
                            }
                        }
                    }
                }
                .task {
                    // Initialize notification permissions
                    NotificationManager.shared.requestAuthorization()
                    // Initialize HealthKit (silent authorization)
                    await healthKit.requestAuthorization()
                    // Check purchase status
                    await subscription.checkPurchaseStatus()
                }
        }
        .modelContainer(for: [VisitRecord.self, Medication.self, FamilyMember.self])
    }
}
