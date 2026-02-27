import Foundation
import SwiftUI
import SwiftData

@Model
final class Project {
    var id: UUID
    var name: String
    var colorHex: String
    var createdAt: Date

    init(name: String, colorHex: String) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.createdAt = Date()
    }

    var color: Color {
        Color(hex: colorHex)
    }

    static let projectColors: [String] = [
        "#FF6B6B", "#339AF0", "#00C9A7", "#FFA94D",
        "#E599F7", "#FF922B", "#20C997", "#4DABF7",
    ]
}
