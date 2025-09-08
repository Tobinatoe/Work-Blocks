import SwiftUI

struct MainView: View {
    @EnvironmentObject var timer: TimerStore
    @EnvironmentObject var storage: Storage

    var body: some View {
        VStack(spacing: 12) {
            // Big number = blocks today
            Text("\(timer.todayBlocks)")
                .font(.system(size: 128, weight: .bold, design: .rounded))
                .monospacedDigit()

            // Minutes + hours today
            Text("\(timer.todayMinutes) min  •  \(formatH(timer.todayMinutes))")
                .font(.title3)
                .foregroundStyle(.secondary)

            // Week summary
            Text("This week: \(timer.weekBlocks) blocks")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            // Progress ring for current block
            ProgressView(value: min(Double(timer.elapsedSec) / Double(Config.blockLengthMinutes * 60), 1.0))
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .padding(.horizontal, 24)

            Text(remainingText)
                .font(.caption)
                .foregroundStyle(.secondary)

            // Controls
            HStack(spacing: 12) {
                Button(action: { timer.start() }) {
                    Label(timer.state == .paused || timer.state == .idle || timer.state == .completed ? "Start" : "Resume", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(timer.state == .running)

                Button(action: { timer.pause() }) {
                    Label("Pause", systemImage: "pause.fill")
                }
                .buttonStyle(.bordered)
                .disabled(timer.state != .running)

                Button(role: .destructive, action: { timer.reset() }) {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)

                Button(action: { timer.addCompletedBlock() }) {
                    Label("Add", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.bordered)
                .disabled(timer.state != .completed)
            }
            .padding(.top, 4)
        }
        .padding(24)
        .frame(minWidth: 440, minHeight: 420)
    }

    private var remainingText: String {
        let total = Config.blockLengthMinutes * 60
        let rem = max(0, total - timer.elapsedSec)
        let mm = rem / 60
        let ss = rem % 60
        switch timer.state {
        case .running: return String(format: "Remaining: %02d:%02d", mm, ss)
        case .paused: return "Paused"
        case .completed: return "Block complete"
        case .idle: return String(format: "Ready • %d min block", Config.blockLengthMinutes)
        }
    }

    private func formatH(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        return "\(h)h \(m)m"
    }
}
