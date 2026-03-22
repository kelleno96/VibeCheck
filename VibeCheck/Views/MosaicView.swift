import SwiftUI
import SwiftData

struct MosaicView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("selectedThemeIndex") private var selectedThemeIndex = 0

    @Query(sort: \MoodEntry.date) private var entries: [MoodEntry]
    @Bindable var viewModel: MosaicViewModel

    private var theme: ColorTheme {
        ColorTheme.theme(at: selectedThemeIndex)
    }

    private let darkBackground = Color(white: 0.08)

    /// The color indices to display — either real entries or dev preview.
    private var displayColors: [Int] {
        if viewModel.devPreviewCount > 0 {
            return viewModel.devPreviewColors
        }
        return entries.map { $0.colorIndex }
    }

    var body: some View {
        let colors = displayColors
        let columns = viewModel.columnCount

        // Pad the front so the last entry always lands at the rightmost column
        let remainder = colors.count % columns
        let leadingPad = remainder == 0 ? 0 : columns - remainder

        GeometryReader { geo in
            let cellSize = geo.size.width / CGFloat(columns)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        // Build rows manually: first row has leading padding
                        let allCells = Array(repeating: -1, count: leadingPad) + colors
                        let rows = allCells.chunked(into: columns)

                        ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                            HStack(spacing: 0) {
                                ForEach(Array(row.enumerated()), id: \.offset) { _, colorIndex in
                                    if colorIndex < 0 {
                                        Rectangle()
                                            .fill(darkBackground)
                                            .frame(width: cellSize, height: cellSize)
                                    } else {
                                        Rectangle()
                                            .fill(theme.colors[colorIndex])
                                            .frame(width: cellSize, height: cellSize)
                                    }
                                }
                            }
                        }
                    }
                    Color.clear.frame(height: 60).id("bottom")
                }
                .onAppear {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
                .onChange(of: colors.count) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
        .background(darkBackground)
        .overlay(alignment: .bottom) {
            bottomBar
        }
        .sheet(isPresented: $viewModel.showingColorPicker) {
            ColorPickerSheet()
                .presentationBackground(darkBackground)
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        let count = displayColors.count

        return HStack {
            if count > 0 {
                Text("\(count)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()

            Button {
                viewModel.showingColorPicker = true
            } label: {
                let todayHasEntry = entries.last.map {
                    Calendar.current.isDateInToday($0.date)
                } ?? false
                Image(systemName: todayHasEntry ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 32))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(todayHasEntry ? .green : Color.accentColor)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Array chunking helper

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Preview

#Preview {
    MosaicSamplePreview()
}

private struct MosaicSamplePreview: View {
    @State private var container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: MoodEntry.self, configurations: config)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let context = container.mainContext

        for dayOffset in 0..<217 {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                let entry = MoodEntry(date: date, colorIndex: Int.random(in: 0...4))
                context.insert(entry)
            }
        }
        return container
    }()

    @State private var viewModel = MosaicViewModel()

    var body: some View {
        MosaicView(viewModel: viewModel)
            .modelContainer(container)
    }
}
