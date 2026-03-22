import SwiftUI
import SwiftData

let appGroupID = "group.com.oconnorkellen.vibecheck"

@main
struct VibeCheckApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema(versionedSchema: MoodEntrySchemaV1.self)

        guard let storeURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent("VibeCheck.store") else {
            fatalError("Could not find App Group container")
        }

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: storeURL
        )

        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: MoodEntryMigrationPlan.self,
                configurations: [modelConfiguration]
            )
        } catch {
            print("Failed to create ModelContainer: \(error). Attempting to recover...")
            try? FileManager.default.removeItem(at: storeURL)
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

    init() {
        // Sync theme index to shared UserDefaults for widget
        let themeIndex = UserDefaults.standard.integer(forKey: "selectedThemeIndex")
        UserDefaults(suiteName: appGroupID)?.set(themeIndex, forKey: "selectedThemeIndex")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
