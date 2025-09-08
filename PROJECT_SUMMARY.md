# WorkBlocks v2 — Project Summary

## Overview
WorkBlocks v2 is a macOS SwiftUI app that helps you track focused "work blocks" of a configurable length (default 50 minutes). It provides a simple main window and a Menu Bar item for quick control. When a block completes, you can log it to a local Core Data (SQLite) store and optionally play a completion sound.

## Architecture at a Glance
- UI: SwiftUI views (`MainView`, `MenuBarView`) + `MenuBarExtra` for the status bar item.
- State: `TimerStore` (ObservableObject) manages timer lifecycle, progress, and daily/weekly stats.
- Persistence: `Storage` wraps a Core Data stack with a programmatic model (`Models.swift`) backed by SQLite.
- Lifecycle: `LifecycleService` listens to macOS sleep/wake and prompts stat refresh after wake.
- Config: `Config` reads environment variables for DB path, block length, week start, and sound name.
- Sound: `SoundService` plays a completion sound via `NSSound`.

Entry point is `WorkBlocks_v2App` (marked `@main`). It wires `Storage`, `TimerStore`, and `LifecycleService` into the environment and exposes both the main window and a menu bar extra.

## Key Files
- `WorkBlocks_v2App.swift`: App entry (@main). Creates and injects shared `Storage`, `TimerStore`, and `LifecycleService`. Hosts `MainView` and `MenuBarExtra`.
- `MainView.swift`: Primary window UI: big counter, minutes summary, weekly blocks, progress bar, and controls (Start/Pause/Reset/Add Completed Block).
- `MenuBarView.swift`: Compact UI in the menu bar popover with the same core controls and quick stats.
- `TimerStore.swift`: Core state machine and timer loop.
  - States: `idle`, `running`, `paused`, `completed` (reaches block length).
  - Uses `DispatchSourceTimer` to tick every second; transitions to `completed` when `elapsedSec >= blockLenSec`.
  - `addCompletedBlock` persists a completed block and resets to `idle` (plays sound via `SoundService`).
  - Publishes: `state`, `elapsedSec`, `todayBlocks`, `todayMinutes`, `weekBlocks`.
- `Storage.swift`: Core Data stack and queries.
  - SQLite store (WAL, history tracking) at `Config.dbPath`.
  - Ensures a singleton `Session` row exists to recover timer state across launches.
  - Provides `todayStats()`, `weekBlocks()`, and session read/update helpers.
- `Models.swift`: Programmatic Core Data model.
  - Entities:
    - `Block`: `id`, `started_at`, `ended_at`, `duration_sec`, `status` ("completed"/"aborted"), `tag?`.
    - `Session`: `id=1`, `started_at?`, `paused_accum_sec`, `last_paused_at?`.
- `Config.swift`: Environment-driven configuration with sensible defaults.
- `LifecycleService.swift`: Hooks for macOS sleep/wake (`NSWorkspace`) to refresh stats after wake.
- `SoundService.swift`: Plays the configured completion sound.
- `Assets.xcassets/`: App icons/colors (standard Xcode scaffolding).
- `WorkBlocks_v2.entitlements`: App Sandbox enabled; user-selected read-only file access.

## Data & Persistence
- Backend: Core Data (SQLite) with WAL enabled.
- Database path: default `~/Library/Application Support/WorkBlocks/blocks.sqlite` unless `DB_PATH` is set.
- `Block` rows are only inserted on explicit "Add Completed Block"; live/partial progress isn't persisted as a `Block`.
- `Session` maintains resilience across restarts and sleep/wake via timestamps and accumulated paused seconds.

## Configuration (Environment Variables)
- `DB_PATH`: Absolute SQLite path. Directory is created if needed.
- `BLOCK_LENGTH_MIN`: Integer minutes per block (default 50).
- `WEEK_STARTS_MONDAY`: "1"/"true" to start week on Monday (default true); otherwise Sunday.
- `SOUND_NAME`: macOS sound name to play when a block is logged (default "Submarine.aiff").

Tip: In Xcode, set these in the scheme: Edit Scheme → Run → Arguments → Environment Variables.

## UI Behavior
- Main window shows:
  - Big number: completed blocks today (`todayBlocks`).
  - Text summary: minutes today and human-friendly hours/minutes.
  - Weekly blocks count.
  - Progress bar: `elapsedSec / (BLOCK_LENGTH_MIN * 60)`.
  - Remaining time text: "Remaining: mm:ss" while running; "Paused", "Block complete", or "Ready · {length} min block" otherwise.
- Controls are enabled/disabled based on `TimerStore.state`.
- Menu bar popover mirrors essential controls and stats.

## Lifecycle & Accuracy
- Elapsed time derives from timestamps (`startedAt`, `lastPausedAt`, `pausedAccumSec`) so sleep/wake or brief app closures remain accurate.
- `LifecycleService` triggers `refreshStats()` on wake.
- An hourly timer refreshes day/week rollovers cheaply without heavy observers.

## Entitlements
- App Sandbox: enabled.
- `com.apple.security.files.user-selected.read-only`: allowed.
- Note: The app writes its database under Application Support inside its container path, which is permitted with sandboxing.

## Running
- Open `WorkBlocks_v2.xcodeproj` in Xcode and run the macOS target.
- Optional: Configure env vars in the scheme for custom DB path, block length, week start day, or sound.

## Known Limitations / Ideas
- Blocks must be explicitly logged after completion (press "Add Completed Block"). Auto-log option could be added.
- No notifications on completion; integrating `NSUserNotificationCenter`/`UNUserNotificationCenter` would help.
- No preferences UI; a simple SwiftUI Settings scene could expose `BLOCK_LENGTH_MIN`, `WEEK_STARTS_MONDAY`, and `SOUND_NAME`.
- Consider menu bar title showing live remaining time.
- Export/import of history could be added (CSV/JSON) with explicit user-selected file permissions.

## Directory Structure (top-level)
- `WorkBlocks_v2/` — app sources and assets
- `WorkBlocks_v2.xcodeproj/` — Xcode project
- `WorkBlocks_v2Tests/`, `WorkBlocks_v2UITests/` — test targets (scaffolded)
