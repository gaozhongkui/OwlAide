import SwiftUI
import SwiftData

@main
struct OwlAideApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [VisitRecord.self, Medication.self])
    }
}
