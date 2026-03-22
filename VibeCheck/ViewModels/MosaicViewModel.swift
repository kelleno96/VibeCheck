import SwiftUI
import SwiftData

@MainActor
@Observable
final class MosaicViewModel {
    var showingColorPicker = false

    let columnCount = 7

    /// Dev-only: number of fake preview colors to display.
    /// When > 0, these replace the real entries in the mosaic display.
    var devPreviewCount: Int = 0
    var devPreviewColors: [Int] = []

    func regenerateDevPreview(count: Int) {
        devPreviewCount = count
        devPreviewColors = (0..<count).map { _ in Int.random(in: 0...4) }
    }

    /// Total number of entries logged (for display).
    func entryCount(from entries: [MoodEntry]) -> Int {
        entries.count
    }
}
