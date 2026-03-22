import SwiftUI

struct SettingsView: View {
    @AppStorage("selectedThemeIndex") private var selectedThemeIndex = 0
    @State private var viewModel = SettingsViewModel()
    var mosaicViewModel: MosaicViewModel

    @State private var devSliderValue: Double = 0

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Theme
                Section("Color Theme") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(ColorTheme.allThemes) { theme in
                                themePreview(theme)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                // MARK: - Notifications
                Section("Daily Reminder") {
                    DatePicker(
                        "Notification Time",
                        selection: $viewModel.notificationTime,
                        displayedComponents: .hourAndMinute
                    )
                }

                // MARK: - About
                Section("About") {
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    Text("VibeCheck tracks your daily mood with a single color. All data stays on your device.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                // MARK: - Developer Options
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preview Colors: \(Int(devSliderValue))")
                            .font(.subheadline)
                            .monospacedDigit()

                        Slider(value: $devSliderValue, in: 0...1500, step: 1)
                            .onChange(of: devSliderValue) { _, newValue in
                                mosaicViewModel.regenerateDevPreview(count: Int(newValue))
                            }

                        Text("Generates random colors from the active theme. Does not affect saved data.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)

                    if mosaicViewModel.devPreviewCount > 0 {
                        Button("Clear Preview") {
                            devSliderValue = 0
                            mosaicViewModel.devPreviewCount = 0
                            mosaicViewModel.devPreviewColors = []
                        }
                        .foregroundStyle(.red)
                    }
                } header: {
                    Text("Developer Options")
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func themePreview(_ theme: ColorTheme) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(theme.colors[index])
                        .frame(width: 20, height: 20)
                }
            }
            Text(theme.name)
                .font(.caption)
                .foregroundStyle(selectedThemeIndex == theme.id ? .primary : .secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(selectedThemeIndex == theme.id ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(selectedThemeIndex == theme.id ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            withAnimation {
                selectedThemeIndex = theme.id
            }
        }
    }
}
