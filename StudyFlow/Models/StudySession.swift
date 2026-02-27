import Foundation
import SwiftData

@Model
final class StudySession {
    var id: UUID
    var subjectName: String
    var subjectColorHex: String
    var duration: Int // seconds
    var startDate: Date
    var endDate: Date
    var pomodoroCount: Int
    var projectName: String
    var projectColorHex: String

    init(
        subjectName: String,
        subjectColorHex: String,
        duration: Int,
        startDate: Date,
        endDate: Date,
        pomodoroCount: Int = 1,
        projectName: String = "",
        projectColorHex: String = ""
    ) {
        self.id = UUID()
        self.subjectName = subjectName
        self.subjectColorHex = subjectColorHex
        self.duration = duration
        self.startDate = startDate
        self.endDate = endDate
        self.pomodoroCount = pomodoroCount
        self.projectName = projectName
        self.projectColorHex = projectColorHex
    }

    var formattedDuration: String {
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var timeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startDate)) – \(formatter.string(from: endDate))"
    }
}
