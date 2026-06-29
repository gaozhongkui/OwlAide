import SwiftUI
import SwiftData

enum AppScreen {
    case home
    case prepare
    case record
    case processing
    case summary
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentScreen: AppScreen = .home
    @State private var activeRecord: VisitRecord?
    @StateObject private var aiService = AIService()

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            Group {
                switch currentScreen {
                case .home:
                    HomeView(
                        onPrepareClick: {
                            createNewRecord()
                            withAnimation { currentScreen = .prepare }
                        },
                        onRecordClick: {
                            if activeRecord == nil { createNewRecord() }
                            withAnimation { currentScreen = .record }
                        },
                        onSummaryViewClick: { record in
                            activeRecord = record
                            withAnimation { currentScreen = .summary }
                        }
                    )
                case .prepare:
                    if let record = activeRecord {
                        PrepareView(record: record) {
                            withAnimation { currentScreen = .record }
                        }
                        .transition(.move(edge: .trailing))
                    }
                case .record:
                    RecordView(
                        onStopRecording: {
                            if let record = activeRecord {
                                withAnimation { currentScreen = .processing }
                                aiService.generateSummary(for: record) {
                                    withAnimation { currentScreen = .summary }
                                }
                            }
                        }
                    )
                    .transition(.opacity)
                case .processing:
                    ProcessingView()
                        .transition(.opacity)
                case .summary:
                    SummaryView(record: activeRecord) {
                        activeRecord = nil
                        withAnimation { currentScreen = .home }
                    }
                    .transition(.move(edge: .bottom))
                }
            }
        }
    }

    private func createNewRecord() {
        let newRecord = VisitRecord(department: "心内科", hospital: "北京协和医院")
        modelContext.insert(newRecord)
        activeRecord = newRecord
    }
}
