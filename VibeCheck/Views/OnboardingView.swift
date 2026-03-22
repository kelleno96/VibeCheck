import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("selectedThemeIndex") private var selectedThemeIndex = 0
    @State private var currentPage = 0

    private var theme: ColorTheme {
        ColorTheme.theme(at: selectedThemeIndex)
    }

    var body: some View {
        TabView(selection: $currentPage) {
            welcomePage.tag(0)
            notificationPage.tag(1)
            firstPickPage.tag(2)
        }
        #if os(iOS)
        .tabViewStyle(.page(indexDisplayMode: .never))
        #endif
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "square.grid.3x3.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor)

            Text("VibeCheck")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("One color. One tap. Every day.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                withAnimation { currentPage = 1 }
            } label: {
                Text("Get Started")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Page 2: Notifications

    private var notificationPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor)

            Text("Stay on Track")
                .font(.title)
                .fontWeight(.bold)

            Text("Get a gentle nudge each evening\nto log your mood.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    Task {
                        let granted = await NotificationManager.shared.requestAuthorization()
                        if granted {
                            NotificationManager.shared.scheduleDailyNotification(hour: 20, minute: 0)
                        }
                        withAnimation { currentPage = 2 }
                    }
                } label: {
                    Text("Enable Notifications")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    withAnimation { currentPage = 2 }
                } label: {
                    Text("Skip for Now")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Page 3: First Color Pick

    private var firstPickPage: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("How's the vibe today?")
                .font(.title2)
                .fontWeight(.semibold)

            HStack(spacing: 20) {
                ForEach(0..<5, id: \.self) { index in
                    VStack(spacing: 8) {
                        Circle()
                            .fill(theme.colors[index])
                            .frame(width: 56, height: 56)
                            .onTapGesture {
                                selectFirstColor(index)
                            }

                        Text(theme.moodLabels[index])
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding()
    }

    private func selectFirstColor(_ index: Int) {
        let entry = MoodEntry(date: Date(), colorIndex: index)
        modelContext.insert(entry)
        hasCompletedOnboarding = true
    }
}
