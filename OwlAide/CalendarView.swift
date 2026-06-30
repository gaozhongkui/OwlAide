import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query(sort: \VisitRecord.date, order: .forward) var records: [VisitRecord]
    @StateObject private var settings = AppSettings.shared

    var body: some View {
        VStack(spacing: 0) {
            Text("Visit Schedule")
                .font(AppTheme.titleFont)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.white)

            ScrollView {
                VStack(spacing: 16) {
                    // Upcoming Visits (filter future records from real data)
                    let upcomingVisits = records.filter { $0.date >= Date() }
                    if let nextVisit = upcomingVisits.first {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Upcoming")
                                    .font(AppTheme.captionFont)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(AppTheme.teal)
                                    .cornerRadius(4)
                                Spacer()
                                Text(formatDate(nextVisit.date) + " " + formatTime(nextVisit.date))
                                    .font(AppTheme.captionFont)
                                    .foregroundColor(.gray)
                            }

                            Text("\(nextVisit.department) Follow-up")
                                .font(AppTheme.titleFont)
                            Text("\(nextVisit.hospital)")
                                .font(AppTheme.bodyFont)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 10)

                        // Future Visits
                        if upcomingVisits.count > 1 {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Future Visits")
                                    .font(AppTheme.captionFont)
                                    .foregroundColor(.gray)
                                ForEach(upcomingVisits.dropFirst()) { visit in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\(visit.department) · \(visit.hospital)")
                                                .font(AppTheme.bodyFont)
                                            Text(formatDate(visit.date))
                                                .font(AppTheme.captionFont)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                        Image(systemName: "calendar.badge.clock")
                                            .foregroundColor(AppTheme.teal)
                                    }
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                }
                            }
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 50))
                                .foregroundColor(AppTheme.tealLight)
                            Text("No upcoming visits")
                                .font(AppTheme.bodyFont)
                                .foregroundColor(.gray)
                            Text("Tap 'Prepare' on the Home screen to create a new visit record.")
                                .font(AppTheme.captionFont)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .background(Color.white)
                        .cornerRadius(16)
                    }

                    // History
                    let pastVisits = records.filter { $0.date < Date() }
                    if !pastVisits.isEmpty {
                        Text("History")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top)

                        ForEach(pastVisits.sorted(by: { $0.date > $1.date })) { record in
                            HistoryItem(
                                date: "\(formatShortDate(record.date)) · \(record.department)",
                                title: record.hospital,
                                isActive: false
                            )
                        }
                    }
                }
                .padding()
            }
        }
        .background(settings.backgroundColor)
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "MMM d, EEEE"
        return f.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    private func formatShortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}
