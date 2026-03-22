import Foundation
import SwiftData

enum MoodEntrySchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [MoodEntry.self]
    }

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
}

enum MoodEntryMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [MoodEntrySchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}

typealias MoodEntry = MoodEntrySchemaV1.MoodEntry
