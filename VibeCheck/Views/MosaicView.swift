import SwiftUI
import SwiftData

struct MosaicView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("selectedThemeIndex") private var selectedThemeIndex = 0

    @Query(sort: \MoodEntry.date) private var entries: [MoodEntry]
    @Bindable var viewModel: MosaicViewModel

    @State private var hasCheckedToday = false

    private var theme: ColorTheme {
        ColorTheme.theme(at: selectedThemeIndex)
    }

    private let darkBackground = Color(white: 0.08)

    private var displayColors: [Int] {
        if viewModel.devPreviewCount > 0 {
            return viewModel.devPreviewColors
        }
        return entries.map { $0.colorIndex }
    }

    private var todayHasEntry: Bool {
        entries.last.map { Calendar.current.isDateInToday($0.date) } ?? false
    }

    var body: some View {
        MosaicScrollView(
            colors: displayColors,
            themeColors: theme.colors.map { UIColor($0) },
            columnCount: $viewModel.columnCount,
            darkBackground: UIColor(darkBackground),
            onLongPress: {
                viewModel.showingSettings = true
            }
        )
        .background(darkBackground)
        .ignoresSafeArea()
        .onAppear {
            if !hasCheckedToday {
                hasCheckedToday = true
                if !todayHasEntry {
                    viewModel.showingColorPicker = true
                }
            }
        }
        .sheet(isPresented: $viewModel.showingColorPicker) {
            ColorPickerSheet()
                .presentationBackground(darkBackground)
        }
        .sheet(isPresented: $viewModel.showingSettings) {
            SettingsView(mosaicViewModel: viewModel)
                .presentationBackground(darkBackground)
        }
    }
}

// MARK: - UIKit-backed mosaic

#if os(iOS)

private struct MosaicScrollView: UIViewRepresentable {
    let colors: [Int]
    let themeColors: [UIColor]
    @Binding var columnCount: Int
    let darkBackground: UIColor
    let onLongPress: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MosaicUIView {
        let view = MosaicUIView()
        view.coordinator = context.coordinator
        context.coordinator.onLongPress = onLongPress
        context.coordinator.onColumnCountChange = { [self] newCount in
            self.columnCount = newCount
        }
        return view
    }

    func updateUIView(_ view: MosaicUIView, context: Context) {
        context.coordinator.onLongPress = onLongPress
        context.coordinator.onColumnCountChange = { [self] newCount in
            self.columnCount = newCount
        }
        context.coordinator.columnCount = columnCount

        view.update(
            colors: colors,
            themeColors: themeColors,
            columnCount: columnCount,
            darkBackground: darkBackground
        )
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onLongPress: (() -> Void)?
        var onColumnCountChange: ((Int) -> Void)?
        var columnCount: Int = 7
        var lastScale: CGFloat = 1.0
        var accumulatedDelta: CGFloat = 0.0

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            true
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            switch gesture.state {
            case .began:
                lastScale = gesture.scale
                accumulatedDelta = 0
            case .changed:
                let delta = gesture.scale - lastScale
                accumulatedDelta += delta
                lastScale = gesture.scale

                let threshold: CGFloat = 0.15
                if accumulatedDelta > threshold {
                    accumulatedDelta = 0
                    let newCount = max(MosaicViewModel.minColumns, columnCount - 1)
                    if newCount != columnCount {
                        columnCount = newCount
                        DispatchQueue.main.async { self.onColumnCountChange?(newCount) }
                    }
                } else if accumulatedDelta < -threshold {
                    accumulatedDelta = 0
                    let newCount = min(MosaicViewModel.maxColumns, columnCount + 1)
                    if newCount != columnCount {
                        columnCount = newCount
                        DispatchQueue.main.async { self.onColumnCountChange?(newCount) }
                    }
                }
            case .ended, .cancelled:
                lastScale = 1.0
                accumulatedDelta = 0
            default:
                break
            }
        }

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            if gesture.state == .began {
                DispatchQueue.main.async { self.onLongPress?() }
            }
        }
    }
}

private class MosaicUIView: UIView {
    var coordinator: MosaicScrollView.Coordinator?

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private var colors: [Int] = []
    private var themeColors: [UIColor] = []
    private var columnCount: Int = 7
    private var bgColor: UIColor = .black
    private var cellLayers: [CALayer] = []
    private var previousColorCount: Int = -1
    private var needsScrollToBottom = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        addSubview(scrollView)
        scrollView.addSubview(contentView)
    }

    func attachGestures() {
        guard let coordinator else { return }
        // Only add once
        if scrollView.gestureRecognizers?.contains(where: { $0 is UIPinchGestureRecognizer }) == true {
            return
        }

        let pinch = UIPinchGestureRecognizer(target: coordinator, action: #selector(MosaicScrollView.Coordinator.handlePinch(_:)))
        pinch.delegate = coordinator
        scrollView.addGestureRecognizer(pinch)

        let longPress = UILongPressGestureRecognizer(target: coordinator, action: #selector(MosaicScrollView.Coordinator.handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        scrollView.addGestureRecognizer(longPress)
    }

    func update(colors: [Int], themeColors: [UIColor], columnCount: Int, darkBackground: UIColor) {
        self.colors = colors
        self.themeColors = themeColors
        self.columnCount = columnCount
        self.bgColor = darkBackground
        scrollView.backgroundColor = darkBackground
        backgroundColor = darkBackground

        if colors.count != previousColorCount {
            needsScrollToBottom = true
        }

        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = bounds
        attachGestures()
        rebuildGrid()
    }

    private func rebuildGrid() {
        let width = bounds.width
        guard width > 0, columnCount > 0 else { return }

        // Clear old layers
        for layer in cellLayers {
            layer.removeFromSuperlayer()
        }
        cellLayers.removeAll()

        let cellSize = width / CGFloat(columnCount)
        let remainder = colors.count % columnCount
        let leadingPad = (colors.isEmpty || remainder == 0) ? 0 : columnCount - remainder
        let totalCells = leadingPad + colors.count
        let rowCount = totalCells > 0 ? (totalCells + columnCount - 1) / columnCount : 0
        let contentHeight = CGFloat(rowCount) * cellSize
        let minHeight = max(contentHeight, bounds.height)
        let topOffset = minHeight - contentHeight

        contentView.frame = CGRect(x: 0, y: 0, width: width, height: minHeight)
        scrollView.contentSize = CGSize(width: width, height: minHeight)

        let bgCG = bgColor.cgColor

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        for i in 0..<totalCells {
            let row = i / columnCount
            let col = i % columnCount
            let x = CGFloat(col) * cellSize
            let y = topOffset + CGFloat(row) * cellSize

            let layer = CALayer()
            layer.frame = CGRect(x: x, y: y, width: cellSize, height: cellSize)

            if i < leadingPad {
                layer.backgroundColor = bgCG
            } else {
                let colorIndex = colors[i - leadingPad]
                let clamped = min(max(colorIndex, 0), themeColors.count - 1)
                layer.backgroundColor = themeColors[clamped].cgColor
            }

            contentView.layer.addSublayer(layer)
            cellLayers.append(layer)
        }

        CATransaction.commit()

        if needsScrollToBottom {
            needsScrollToBottom = false
            previousColorCount = colors.count
            let bottomOffset = max(0, scrollView.contentSize.height - scrollView.bounds.height)
            scrollView.contentOffset = CGPoint(x: 0, y: bottomOffset)
        }
    }
}

#endif

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
