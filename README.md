# WorkBlocks (macOS)

A tiny, focused macOS app to track deep‑work in fixed‑length “blocks.” Start a block, focus, and when time’s up the app dings. One click to log the block with an optional tag, then see your day and week add up.

## What it does
- Fixed‑length work blocks (default 50 minutes; configurable)
- Simple controls in a small window and the menu bar
- Live progress and remaining time for the current block
- Add the completed block with an optional description/tag
- Today stats: blocks completed and minutes total
- Week stats: total blocks this week
- History: browse weeks, see daily and weekly totals

## How it works
- Timer logic is timestamp‑based and resilient to pause/resume and sleep/wake.
- When a block completes, you’ll hear a macOS sound (configurable).
- Block completions are stored locally in a lightweight Core Data SQLite store. No cloud, no network.

## Key screens
- Main view: big count of today’s blocks, today’s minutes, week total, progress of current block, Start/Pause/Reset, and an Add button to log a finished block with a tag.
- Menu bar: quick glance at today/week and quick actions (Start/Pause/Reset, Add when complete).
- History: weekly list; drill down to see per‑day stats and weekly totals.

## Configuration
You can override defaults using environment variables (set in the Xcode scheme or when launching):
- DB_PATH: absolute path to the SQLite file. Default: ~/Library/Application Support/WorkBlocks/blocks.sqlite
- BLOCK_LENGTH_MIN: integer length of a block in minutes. Default: 50
- WEEK_STARTS_MONDAY: "1"/"0" or true/false. Default: 1 (Monday)
- SOUND_NAME: macOS sound name to play on completion. Default: Submarine.aiff

## Data and privacy
- Data lives locally in the SQLite database defined by DB_PATH.
- No accounts, telemetry, or network access.

## Build and run
- Open `WorkBlocks_v2.xcodeproj` in Xcode (macOS app).
- The app target is `WorkBlocks_v2`.
- Run. The menu bar item (timer icon) appears; the main window shows Today and History tabs.

## Tech notes
- SwiftUI app; Core Data model is built in code (`ModelBuilder`).
- Timer state machine in `TimerStore` (idle/running/paused/completed).
- Storage and queries in `Storage` (today/week stats, history).
- Behavior on sleep/wake handled by `LifecycleService`.
- Completion sound via `NSSound` (`SoundService`).

## License
TBD.
