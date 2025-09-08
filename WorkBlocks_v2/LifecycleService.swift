import AppKit
import Combine

final class LifecycleService: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private weak var timerStore: TimerStore?

    func bootstrap(timerStore: TimerStore) {
        self.timerStore = timerStore

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(willSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(didWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    @objc private func willSleep() {
        // Nothing special; elapsed is timestamp-derived.
    }

    @objc private func didWake() {
        // Recompute elapsed & stats
        timerStore?.refreshStats()
    }
}
