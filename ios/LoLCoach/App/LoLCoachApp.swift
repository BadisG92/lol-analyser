import SwiftUI
import SwiftData

@main
struct LoLCoachApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [GameSession.self])
    }
}

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            if appState.isSetupComplete {
                HomeView()
            } else {
                SetupView(wrapsInNavigationStack: false)
            }
        }
        .tint(Color(hex: 0xC89B3C))
    }
}
