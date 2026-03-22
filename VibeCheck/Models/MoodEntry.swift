import Foundation
import SwiftData

@Model
final class MoodEntry {
    var id: UUID
    var date: Date
    var colorIndex: Int
    var createdAt: Date
    var updatedAt: Date

    init(date: Date, colorIndex: Int) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.colorIndex = colorIndex
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
