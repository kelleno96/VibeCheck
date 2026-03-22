import SwiftUI
import SwiftData

@main
struct VibeCheckApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema(versionedSchema: MoodEntrySchemaV1.self)
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: MoodEntryMigrationPlan.self,
                configurations: [modelConfiguration]
            )
        } catch {
            // If the store is corrupted, delete it and start fresh as a last resort.
            // This should only happen during development.
            print("Failed to create ModelContainer: \(error). Attempting to recover...")
            let storeURL = modelConfiguration.url
            try? FileManager.default.removeItem(at: storeURL)
            // Also remove journal files
            let storeDir = storeURL.deletingLastPathComponent()
            try? FileManager.default.removeItem(at: storeDir.appendingPathComponent(storeURL.lastPathComponent + "-wal"))
            try? FileManager.default.removeItem(at: storeDir.appendingPathComponent(storeURL.lastPathComponent + "-shm"))

            do {
                return try ModelContainer(
                    for: schema,
                    migrationPlan: MoodEntryMigrationPlan.self,
                    configurations: [modelConfiguration]
                )
            } catch {
                fatalError("Could not create ModelContainer after recovery: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
