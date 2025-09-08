import AppKit

struct SoundService {
    static func playCompletionSound() {
        NSSound(named: NSSound.Name(Config.soundName))?.play()
    }
}
