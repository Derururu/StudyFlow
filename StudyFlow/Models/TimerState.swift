import Foundation

enum TimerPhase: String, CaseIterable {
    case focus = "Focus"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"

    var defaultDuration: Int {
        switch self {
        case .focus: return 25 * 60
        case .shortBreak: return 5 * 60
        case .longBreak: return 15 * 60
        }
    }

    var emoji: String {
        switch self {
        case .focus: return "🎯"
        case .shortBreak: return "☕"
        case .longBreak: return "🌿"
        }
    }
}

enum TimerStatus {
    case idle
    case running
    case paused
}

struct TimerConfig {
    var focusDuration: Int = 25 * 60
    var shortBreakDuration: Int = 5 * 60
    var longBreakDuration: Int = 15 * 60
    var longBreakInterval: Int = 4
    var soundEnabled: Bool = true
    var notificationsEnabled: Bool = true

    func duration(for phase: TimerPhase) -> Int {
        switch phase {
        case .focus: return focusDuration
        case .shortBreak: return shortBreakDuration
        case .longBreak: return longBreakDuration
        }
    }

    // Persistence keys
    static let focusKey = "timerConfig.focusDuration"
    static let shortBreakKey = "timerConfig.shortBreakDuration"
    static let longBreakKey = "timerConfig.longBreakDuration"
    static let longBreakIntervalKey = "timerConfig.longBreakInterval"
    static let soundKey = "timerConfig.soundEnabled"
    static let notificationsKey = "timerConfig.notificationsEnabled"

    static func load() -> TimerConfig {
        let defaults = UserDefaults.standard
        return TimerConfig(
            focusDuration: defaults.object(forKey: focusKey) as? Int ?? 25 * 60,
            shortBreakDuration: defaults.object(forKey: shortBreakKey) as? Int ?? 5 * 60,
            longBreakDuration: defaults.object(forKey: longBreakKey) as? Int ?? 15 * 60,
            longBreakInterval: defaults.object(forKey: longBreakIntervalKey) as? Int ?? 4,
            soundEnabled: defaults.object(forKey: soundKey) as? Bool ?? true,
            notificationsEnabled: defaults.object(forKey: notificationsKey) as? Bool ?? true
        )
    }

    func save() {
        let defaults = UserDefaults.standard
        defaults.set(focusDuration, forKey: TimerConfig.focusKey)
        defaults.set(shortBreakDuration, forKey: TimerConfig.shortBreakKey)
        defaults.set(longBreakDuration, forKey: TimerConfig.longBreakKey)
        defaults.set(longBreakInterval, forKey: TimerConfig.longBreakIntervalKey)
        defaults.set(soundEnabled, forKey: TimerConfig.soundKey)
        defaults.set(notificationsEnabled, forKey: TimerConfig.notificationsKey)
    }
}
