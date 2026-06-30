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
    @Query(sort: \VisitRecord.date, order: .reverse) private var records: [VisitRecord]
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
                        onStopRecording: { url in
                            if let record = activeRecord {
                                // 保存录音路径到数据库
                                if let url = url {
                                    record.audioPath = url.lastPathComponent
                                }

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
        let lastRecord = records.first
        let newRecord = VisitRecord(
            department: lastRecord?.department ?? "",
            hospital: lastRecord?.hospital ?? ""
        )
        modelContext.insert(newRecord)
        activeRecord = newRecord
        // 自动创建复诊提醒（就诊前一天通知）
        NotificationManager.shared.scheduleFollowUpReminder(visitRecord: newRecord)
    }
}
