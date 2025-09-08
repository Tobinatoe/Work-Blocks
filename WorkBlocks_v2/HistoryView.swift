import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var storage: Storage

    @State private var weekStarts: [Date] = []

    var body: some View {
        NavigationStack {
            List(weekStarts, id: \.self) { weekStart in
                NavigationLink(destination: WeekDetailView(weekStart: weekStart)) {
                    WeekRow(weekStart: weekStart)
                }
            }
            .navigationTitle("History")
            .onAppear { reloadWeeks() }
        }
    }

    private func reloadWeeks() {
        weekStarts = storage.listRecentWeekStarts(limit: 26) // ~half a year
    }
}

private struct WeekRow: View {
    @EnvironmentObject var storage: Storage
    let weekStart: Date

    var body: some View {
        let stats = storage.weeklyStats(forWeekStarting: weekStart)
        VStack(alignment: .leading, spacing: 4) {
            Text(weekLabel(weekStart))
                .font(.headline)
            Text("\(stats.blocks) blocks • \(stats.minutes) min")
                .foregroundStyle(.secondary)
        }
    }

    private func weekLabel(_ date: Date) -> String {
        let cal = Calendar(identifier: .gregorian)
        let end = cal.date(byAdding: .day, value: 6, to: date)!
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return "\(f.string(from: date)) – \(f.string(from: end))"
    }
}
