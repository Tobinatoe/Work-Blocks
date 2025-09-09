import Foundation
import Combine

enum TimerState {
    case idle
    case running
    case paused
    case completed  // >= block length
}

final class TimerStore: ObservableObject {
    // Public UI state
    @Published private(set) var state: TimerState = .idle
    @Published private(set) var elapsedSec: Int = 0
    @Published private(set) var todayBlocks: Int = 0
    @Published private(set) var todayMinutes: Int = 0
    @Published private(set) var weekBlocks: Int = 0

    private var storage: Storage!
    private var timer: DispatchSourceTimer?
    private var cancellables = Set<AnyCancellable>()

    // Timestamps for accurate tracking
    private var startedAt: Date?
    private var pausedAccumSec = 0
    private var lastPausedAt: Date?

    private var blockLenSec: Int { Config.blockLengthMinutes * 60 }

    func bootstrap(storage: Storage) {
        self.storage = storage
        // Load session from DB
        let s = storage.readSessionState()
        startedAt = s.startedAt
        pausedAccumSec = s.pausedAccum
        lastPausedAt = s.lastPausedAt

        // Recompute elapsed
        tickOnce()
        refreshStats()

        if startedAt != nil && lastPausedAt == nil {
            startTimerLoop()
            state = elapsedSec >= blockLenSec ? .completed : .running
        } else if startedAt != nil && lastPausedAt != nil {
            state = elapsedSec >= blockLenSec ? .completed : .paused
        } else {
            state = .idle
        }

        // Midnight rollover: re-check stats hourly (cheap & simple)
        Timer.publish(every: 3600, on: .current, in: .common).autoconnect()
            .sink { [weak self] _ in self?.refreshStats() }
            .store(in: &cancellables)
    }

    // MARK: - Intent
    func start() {
        guard state == .idle || state == .paused || state == .completed else { return }
        if state == .idle || state == .completed {
            startedAt = Date()
            pausedAccumSec = 0
            lastPausedAt = nil
        } else if state == .paused {
            // resume
            if let lp = lastPausedAt {
                pausedAccumSec += Int(Date().timeIntervalSince(lp))
                lastPausedAt = nil
            }
        }
        storage.setSession(startedAt: startedAt)
        storage.setSessionPaused(at: nil)
        storage.addPausedAccum(0) // no-op to mark touch
        startTimerLoop()
        tickOnce()
        state = elapsedSec >= blockLenSec ? .completed : .running
    }

    func pause() {
        guard state == .running else { return }
        lastPausedAt = Date()
        storage.setSessionPaused(at: lastPausedAt)
        stopTimerLoop()
        tickOnce()
        state = elapsedSec >= blockLenSec ? .completed : .paused
    }

    func reset() {
        // Abort current block (doesn't log)
        stopTimerLoop()
        startedAt = nil
        pausedAccumSec = 0
        lastPausedAt = nil
        storage.setSession(startedAt: nil)
        elapsedSec = 0
        state = .idle
    }

    func addCompletedBlock(withTag tag: String?) {
        guard state == .completed else { return }
        guard let start = startedAt else { return }
        let end = start.addingTimeInterval(TimeInterval(blockLenSec))
        storage.insertBlock(.init(startedAt: start, endedAt: end, durationSec: blockLenSec, status: .completed, tag: tag))
        storage.setSession(startedAt: nil)
        startedAt = nil
        pausedAccumSec = 0
        lastPausedAt = nil
        stopTimerLoop()
        elapsedSec = 0
        state = .idle
        refreshStats()
    }

    // MARK: - Timer loop
    private func startTimerLoop() {
        stopTimerLoop()
        let t = DispatchSource.makeTimerSource(queue: .main)
        t.schedule(deadline: .now(), repeating: 1.0)
        t.setEventHandler { [weak self] in
            self?.tickOnce()
            if let self = self, self.elapsedSec >= self.blockLenSec, self.state == .running {
                self.state = .completed
                // Play sound right when the block actually completes
                SoundService.playCompletionSound()
                self.stopTimerLoop()
            }
        }
        t.resume()
        timer = t
    }

    private func stopTimerLoop() {
        timer?.cancel()
        timer = nil
    }

    private func tickOnce() {
        if let startedAt {
            var e = Int(Date().timeIntervalSince(startedAt)) - pausedAccumSec
            if let lp = lastPausedAt { e -= Int(Date().timeIntervalSince(lp)) } // still paused
            elapsedSec = max(0, e)
        } else {
            elapsedSec = 0
        }
    }

    func refreshStats() {
        let t = storage.todayStats()
        todayBlocks = t.blocks
        todayMinutes = t.minutes
        weekBlocks = storage.weekBlocks()
    }
    
        /// Adds a completed block for today, without running the timer.
        func addWorkBlockNow(tag: String? = nil) {
            let now = Date()
            let blockLenSec = Config.blockLengthMinutes * 60
            let start = now
            let end = now.addingTimeInterval(TimeInterval(blockLenSec))
            storage.insertBlock(.init(startedAt: start, endedAt: end, durationSec: blockLenSec, status: .completed, tag: tag))
            refreshStats()
        }
    
        /// Removes the most recent completed block for today.
        func removeWorkBlockNow() {
            storage.removeLatestBlockToday()
            refreshStats()
        }
}
