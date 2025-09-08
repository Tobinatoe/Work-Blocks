import SwiftUI

struct WeekDetailView: View {
    @EnvironmentObject var storage: Storage
    let weekStart: Date

    private var days: [Date] {
        let cal = Calendar(identifier: .gregorian)
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: weekStart) }
    }

    var body: some View {
        let weekTotals = storage.weeklyStats(forWeekStarting: weekStart)
        List {
            Section(header: Text("Summary")) {
                HStack { Text("Blocks"); Spacer(); Text("\(weekTotals.blocks)") }
                HStack { Text("Minutes"); Spacer(); Text("\(weekTotals.minutes)") }
                HStack { Text("Hours"); Spacer(); Text(hoursString(weekTotals.minutes)) }
            }

            Section(header: Text("Per Day")) {
                ForEach(days, id: \.self) { day in
                    let s = storage.stats(forDay: day)
                    HStack {
                        Text(dayLabel(day))
                        Spacer()
                        Text("\(s.blocks) • \(s.minutes) min")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(weekTitle(weekStart))
    }

    private func dayLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("EEE d MMM")
        return f.string(from: date)
    }

    private func weekTitle(_ date: Date) -> String {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("MMM d, yyyy")
        return "Week of \(f.string(from: date))"
    }

    private func hoursString(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        return "\(h)h \(m)m"
    }
}
