import Foundation

enum Config {
    // ENV VARS (set in Xcode scheme or shell)
    // DB_PATH: absolute path to sqlite file (directory created if needed)
    // BLOCK_LENGTH_MIN: default 50
    // WEEK_STARTS_MONDAY: "1" or "0" (default 1)
    // SOUND_NAME: bundled sound file name (default "Submarine.aiff")

    static let dbPath: String = {
        if let path = ProcessInfo.processInfo.environment["DB_PATH"], !path.isEmpty {
            return path
        }
        // Default: ~/Library/Application Support/WorkBlocks/blocks.sqlite
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("WorkBlocks", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("blocks.sqlite").path
    }()

    static let blockLengthMinutes: Int = {
        if let raw = ProcessInfo.processInfo.environment["BLOCK_LENGTH_MIN"], let v = Int(raw), v > 0 {
            return v
        }
        return 50
    }()

    static let weekStartsMonday: Bool = {
        if let raw = ProcessInfo.processInfo.environment["WEEK_STARTS_MONDAY"] {
            return raw == "1" || raw.lowercased() == "true"
        }
        return true
    }()

    static let soundName: String = {
        if let raw = ProcessInfo.processInfo.environment["SOUND_NAME"], !raw.isEmpty {
            return raw
        }
        // Ships with macOS; safe fallback
        return "Submarine.aiff"
    }()
}
