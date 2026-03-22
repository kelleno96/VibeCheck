import WidgetKit
import SwiftUI
import SwiftData

let appGroupID = "group.com.oconnorkellen.vibecheck"

struct MosaicEntry: TimelineEntry {
    let date: Date
    let colorIndices: [Int]
    let themeIndex: Int
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> MosaicEntry {
        MosaicEntry(date: Date(), colorIndices: Array(repeating: 0, count: 49), themeIndex: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (MosaicEntry) -> ()) {
        let entry = fetchEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MosaicEntry>) -> ()) {
        let entry = fetchEntry()
        // Refresh after midnight or in 1 hour, whichever is sooner
        let nextUpdate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchEntry() -> MosaicEntry {
        let shared = UserDefaults(suiteName: appGroupID)
        let themeIndex = shared?.integer(forKey: "selectedThemeIndex") ?? 0

        // Check for dev preview colors first
        if let devColors = shared?.array(forKey: "devPreviewColors") as? [Int], !devColors.isEmpty {
            // Take the last 49 for the widget grid
            let tail = Array(devColors.suffix(49))
            return MosaicEntry(date: Date(), colorIndices: tail, themeIndex: themeIndex)
        }

        var colorIndices: [Int] = []

        do {
            let schema = Schema(versionedSchema: MoodEntrySchemaV1.self)
            guard let storeURL = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
                .appendingPathComponent("VibeCheck.store") else {
                return MosaicEntry(date: Date(), colorIndices: [], themeIndex: themeIndex)
            }

            let config = ModelConfiguration(schema: schema, url: storeURL)
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = ModelContext(container)

            var descriptor = FetchDescriptor<MoodEntry>(sortBy: [SortDescriptor(\MoodEntry.date)])
            descriptor.fetchLimit = 49
            // We want the most recent 49, so sort descending then reverse
            descriptor.sortBy = [SortDescriptor(\MoodEntry.date, order: .reverse)]

            let entries = try context.fetch(descriptor)
            colorIndices = entries.reversed().map { $0.colorIndex }
        } catch {
            print("Widget failed to fetch entries: \(error)")
        }

        return MosaicEntry(date: Date(), colorIndices: colorIndices, themeIndex: themeIndex)
    }
}

struct VibeCheckWidgetEntryView: View {
    var entry: MosaicEntry
    private let columns = 7
    private let darkBackground = Color(white: 0.08)

    private var theme: ColorTheme {
        ColorTheme.theme(at: entry.themeIndex)
    }

    var body: some View {
        let totalCells = columns * columns // 49
        let colors = entry.colorIndices
        let count = colors.count

        // Pad leading cells so entries fill from bottom-right
        let emptyCount = max(totalCells - count, 0)

        GeometryReader { geo in
            let spacing: CGFloat = 1.5
            let totalSpacing = spacing * CGFloat(columns - 1)
            let cellSize = (min(geo.size.width, geo.size.height) - totalSpacing) / CGFloat(columns)

            VStack(spacing: spacing) {
                ForEach(0..<columns, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0..<columns, id: \.self) { col in
                            let index = row * columns + col
                            if index < emptyCount {
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(Color(white: 0.15))
                                    .frame(width: cellSize, height: cellSize)
                            } else {
                                let colorIdx = colors[index - emptyCount]
                                let safeIdx = min(max(colorIdx, 0), theme.colors.count - 1)
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(theme.colors[safeIdx])
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct VibeCheckWidget: Widget {
    let kind: String = "VibeCheckWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                VibeCheckWidgetEntryView(entry: entry)
                    .containerBackground(Color(white: 0.08), for: .widget)
            } else {
                VibeCheckWidgetEntryView(entry: entry)
                    .padding()
                    .background(Color(white: 0.08))
            }
        }
        .configurationDisplayName("VibeCheck Mosaic")
        .description("Your recent mood colors at a glance.")
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    VibeCheckWidget()
} timeline: {
    MosaicEntry(date: .now, colorIndices: (0..<49).map { _ in Int.random(in: 0...4) }, themeIndex: 0)
}
