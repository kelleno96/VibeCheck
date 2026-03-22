import SwiftUI
import SwiftData
import WidgetKit

struct ColorPickerSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedThemeIndex") private var selectedThemeIndex = 0

    @Query(sort: \MoodEntry.date, order: .reverse)
    private var allEntries: [MoodEntry]

    private var theme: ColorTheme {
        ColorTheme.theme(at: selectedThemeIndex)
    }

    private var todayEntry: MoodEntry? {
        let today = DateHelpers.startOfDay(for: Date())
        return allEntries.first { DateHelpers.startOfDay(for: $0.date) == today }
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("How's the vibe?")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            HStack(spacing: 20) {
                ForEach(0..<5, id: \.self) { index in
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(theme.colors[index])
                                .frame(width: 56, height: 56)

                            if todayEntry?.colorIndex == index {
                                Image(systemName: "checkmark")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                        }
                        .onTapGesture {
                            selectColor(index)
                        }

                        Text(theme.moodLabels[index])
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func selectColor(_ index: Int) {
        if let existing = todayEntry {
            existing.colorIndex = index
            existing.updatedAt = Date()
        } else {
            let entry = MoodEntry(date: Date(), colorIndex: index)
            modelContext.insert(entry)
        }
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}
