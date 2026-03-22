import SwiftUI

struct ColorTheme: Identifiable {
    let id: Int
    let name: String
    let colors: [Color]
    let moodLabels: [String]
}

extension ColorTheme {
    static let allThemes: [ColorTheme] = [
        ColorTheme(
            id: 0,
            name: "Sunset",
            colors: [
                Color(hex: 0x2D1B69),
                Color(hex: 0x8B3A62),
                Color(hex: 0xD4775B),
                Color(hex: 0xF2A93B),
                Color(hex: 0xFFD93D)
            ],
            moodLabels: ["Deep low", "Down", "Neutral", "Good", "Great"]
        ),
        ColorTheme(
            id: 1,
            name: "Ocean",
            colors: [
                Color(hex: 0x0B1D3A),
                Color(hex: 0x1B4965),
                Color(hex: 0x5FA8D3),
                Color(hex: 0x62CDCD),
                Color(hex: 0xA8E6CE)
            ],
            moodLabels: ["Deep low", "Down", "Neutral", "Good", "Great"]
        ),
        ColorTheme(
            id: 2,
            name: "Forest",
            colors: [
                Color(hex: 0x1B1B1B),
                Color(hex: 0x4A5240),
                Color(hex: 0x7A8B69),
                Color(hex: 0xA8C686),
                Color(hex: 0xD4E8B0)
            ],
            moodLabels: ["Deep low", "Down", "Neutral", "Good", "Great"]
        ),
        ColorTheme(
            id: 3,
            name: "Neon",
            colors: [
                Color(hex: 0x1A1A2E),
                Color(hex: 0x6B21A8),
                Color(hex: 0xE040FB),
                Color(hex: 0x00E5FF),
                Color(hex: 0x76FF03)
            ],
            moodLabels: ["Deep low", "Down", "Neutral", "Good", "Great"]
        )
    ]

    static func theme(at index: Int) -> ColorTheme {
        allThemes[min(max(index, 0), allThemes.count - 1)]
    }
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
