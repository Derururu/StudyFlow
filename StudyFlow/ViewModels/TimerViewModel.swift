import Foundation
import SwiftUI
import Combine
import UserNotifications
import AppKit

@Observable
final class TimerViewModel {
    var timeRemaining: Int = 25 * 60
    var totalTime: Int = 25 * 60
    var currentPhase: TimerPhase = .focus
    var status: TimerStatus = .idle
    var completedPomodoros: Int = 0
    var config: TimerConfig = .load()
    var showWalkReminder: Bool = false

    var selectedSubjectName: String = "General"
    var selectedSubjectColorHex: String = "#868E96"

    private var timer: AnyCancellable?
    private var sessionStartDate: Date?

    // Callbacks for session logging (set by the view)
    var onSessionCompleted: ((String, String, Int, Date, Date) -> Void)?

    var progress: Double {
        guard totalTime > 0 else { return 0 }
        return 1.0 - (Double(timeRemaining) / Double(totalTime))
    }

    var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var phaseLabel: String {
        "\(currentPhase.emoji) \(currentPhase.rawValue)"
    }

    var canStart: Bool {
        status == .idle || status == .paused
    }

    func start() {
        if status == .idle {
            sessionStartDate = Date()
        }
        status = .running
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func pause() {
        status = .paused
        timer?.cancel()
        timer = nil
    }

    func reset() {
        timer?.cancel()
        timer = nil
        status = .idle
        totalTime = config.duration(for: currentPhase)
        timeRemaining = totalTime
        sessionStartDate = nil
    }

    func skip() {
        timer?.cancel()
        timer = nil
        advancePhase()
    }

    func setPhase(_ phase: TimerPhase) {
        timer?.cancel()
        timer = nil
        status = .idle
        currentPhase = phase
        totalTime = config.duration(for: phase)
        timeRemaining = totalTime
        sessionStartDate = nil
    }

    func updateConfig(_ newConfig: TimerConfig) {
        config = newConfig
        config.save()
        if status == .idle {
            totalTime = config.duration(for: currentPhase)
            timeRemaining = totalTime
        }
    }

    private func tick() {
        guard timeRemaining > 0 else { return }
        timeRemaining -= 1

        if timeRemaining <= 0 {
            timerCompleted()
        }
    }

    private func timerCompleted() {
        timer?.cancel()
        timer = nil
        status = .idle

        if currentPhase == .focus {
            completedPomodoros += 1
            let endDate = Date()
            let startDate = sessionStartDate ?? endDate.addingTimeInterval(-Double(totalTime))

            onSessionCompleted?(
                selectedSubjectName,
                selectedSubjectColorHex,
                totalTime,
                startDate,
                endDate
            )

            // Show walk reminder toast
            showWalkReminder = true
        }

        // Play sound
        if config.soundEnabled {
            NSSound(named: "Glass")?.play()
        }

        // Send notification
        if config.notificationsEnabled {
            sendNotification()
        }

        advancePhase()
    }

    private func advancePhase() {
        status = .idle
        sessionStartDate = nil

        switch currentPhase {
        case .focus:
            if completedPomodoros > 0 && completedPomodoros % config.longBreakInterval == 0 {
                currentPhase = .longBreak
            } else {
                currentPhase = .shortBreak
            }
        case .shortBreak, .longBreak:
            currentPhase = .focus
        }

        totalTime = config.duration(for: currentPhase)
        timeRemaining = totalTime
    }

    private func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "StudyFlow"
        content.sound = .default

        switch currentPhase {
        case .focus:
            content.body = "Focus session complete! Take a break. 🎉"
        case .shortBreak:
            content.body = "Break's over! Ready to focus? 🎯"
        case .longBreak:
            content.body = "Long break's over! Let's get back to it! 💪"
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}
