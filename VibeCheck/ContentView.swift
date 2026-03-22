import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var mosaicViewModel = MosaicViewModel()

    var body: some View {
        if hasCompletedOnboarding {
            TabView {
                MosaicView(viewModel: mosaicViewModel)
                    .tabItem {
                        Label("Mosaic", systemImage: "square.grid.3x3.fill")
                    }

                SettingsView(mosaicViewModel: mosaicViewModel)
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }
        } else {
            OnboardingView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: MoodEntry.self, inMemory: true)
}
