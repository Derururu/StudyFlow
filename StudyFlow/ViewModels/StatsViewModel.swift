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
    var dailyTagBreakdowns: [Date: [(name: String, colorHex: String, duration: Int)]] = [:]
    var selectedProjectFilter: String = ""
    var projectTagBreakdown: [(name: String, colorHex: String, duration: Int)] = []

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

        // Daily totals + per-day tag breakdowns for last 7 days
        var tempDailyTotals: [(date: Date, duration: Int)] = []
        var tempDailyBreakdowns: [Date: [(name: String, colorHex: String, duration: Int)]] = [:]

        for dayOffset in (0..<7).reversed() {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: startOfToday)!
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: date)!
            let daySessions = sessions.filter { $0.startDate >= date && $0.startDate < dayEnd }
            let total = daySessions.reduce(0) { $0 + $1.duration }
            tempDailyTotals.append((date: date, duration: total))

            // Per-day tag breakdown
            var dayTagMap: [String: (colorHex: String, duration: Int)] = [:]
            for session in daySessions {
                let existing = dayTagMap[session.subjectName]
                dayTagMap[session.subjectName] = (
                    colorHex: session.subjectColorHex,
                    duration: (existing?.duration ?? 0) + session.duration
                )
            }
            tempDailyBreakdowns[date] = dayTagMap.map { (name: $0.key, colorHex: $0.value.colorHex, duration: $0.value.duration) }
                .sorted { $0.duration > $1.duration }
        }
        dailyTotals = tempDailyTotals
        dailyTagBreakdowns = tempDailyBreakdowns

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

        // Project tag breakdown (all time, filtered by project)
        if !selectedProjectFilter.isEmpty {
            let projectSessions = sessions.filter { $0.projectName == selectedProjectFilter }
            var tagMap: [String: (colorHex: String, duration: Int)] = [:]
            for session in projectSessions {
                let existing = tagMap[session.subjectName]
                tagMap[session.subjectName] = (
                    colorHex: session.subjectColorHex,
                    duration: (existing?.duration ?? 0) + session.duration
                )
            }
            projectTagBreakdown = tagMap.map { (name: $0.key, colorHex: $0.value.colorHex, duration: $0.value.duration) }
                .sorted { $0.duration > $1.duration }
        } else {
            projectTagBreakdown = []
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
