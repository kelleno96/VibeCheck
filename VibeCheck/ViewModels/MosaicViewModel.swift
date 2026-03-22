import SwiftUI
import SwiftData

@MainActor
@Observable
final class MosaicViewModel {
    var showingColorPicker = false
    var showingSettings = false

    var columnCount: Int = 7

    static let minColumns = 2
    static let maxColumns = 14

    /// Dev-only: number of fake preview colors to display.
    /// When > 0, these replace the real entries in the mosaic display.
    var devPreviewCount: Int = 0
    var devPreviewColors: [Int] = []

    func regenerateDevPreview(count: Int) {
        devPreviewCount = count
        devPreviewColors = (0..<count).map { _ in Int.random(in: 0...4) }
    }
}
