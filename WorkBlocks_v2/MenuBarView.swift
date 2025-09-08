import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var timer: TimerStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today: \(timer.todayBlocks) blocks • \(timer.todayMinutes) min")
            Text("Week: \(timer.weekBlocks) blocks")
                .foregroundStyle(.secondary)

            Divider().padding(.vertical, 4)

            HStack {
                Button(timer.state == .running ? "Running…" : "Start") { timer.start() }
                    .disabled(timer.state == .running)
                Button("Pause") { timer.pause() }
                    .disabled(timer.state != .running)
                Button("Reset", role: .destructive) { timer.reset() }
            }

            Button("Add Completed Block") {
                timer.addCompletedBlock()
            }
            .disabled(timer.state != .completed)
        }
        .padding(12)
        .frame(width: 280)
    }
}
