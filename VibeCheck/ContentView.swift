import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var mosaicViewModel = MosaicViewModel()

    var body: some View {
        if hasCompletedOnboarding {
            MosaicView(viewModel: mosaicViewModel)
        } else {
            OnboardingView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: MoodEntry.self, inMemory: true)
}
