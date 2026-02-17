import Foundation
import SwiftData
import SwiftUI

@Observable
final class StatsViewModel {
    var todayTotal: Int = 0 // seconds
    var weekTotal: Int = 0
    var totalSessions: Int = 0
    var currentStreak: Int = 0
    var todaySessions: Int = 0
    var subjectBreakdown: [(name: String, colorHex: String, duration: Int)] = []
    var dailyTotals: [(date: Date, duration: Int)] = [] // last 7 days

    func refresh(sessions: [StudySession]) {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        // Today's stats
        let todaysSessions = sessions.filter { calendar.isDateInToday($0.startDate) }
        todayTotal = todaysSessions.reduce(0) { $0 + $1.duration }
        todaySessions = todaysSessions.count

        // Week stats
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let weekSessions = sessions.filter { $0.startDate >= startOfWeek }
        weekTotal = weekSessions.reduce(0) { $0 + $1.duration }

        totalSessions = sessions.count

        // Subject breakdown (today)
        var subjectMap: [String: (colorHex: String, duration: Int)] = [:]
        for session in todaysSessions {
            let existing = subjectMap[session.subjectName]
            subjectMap[session.subjectName] = (
                colorHex: session.subjectColorHex,
                duration: (existing?.duration ?? 0) + session.duration
            )
        }
        subjectBreakdown = subjectMap.map { (name: $0.key, colorHex: $0.value.colorHex, duration: $0.value.duration) }
            .sorted { $0.duration > $1.duration }

        // Daily totals for last 7 days
        dailyTotals = (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: startOfToday)!
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: date)!
            let daySessions = sessions.filter { $0.startDate >= date && $0.startDate < dayEnd }
            let total = daySessions.reduce(0) { $0 + $1.duration }
            return (date: date, duration: total)
        }.reversed()

        // Streak calculation
        currentStreak = 0
        var checkDate = startOfToday
        while true {
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: checkDate)!
            let hasSessions = sessions.contains { $0.startDate >= checkDate && $0.startDate < dayEnd }
            if hasSessions {
                currentStreak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
    }

    func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
