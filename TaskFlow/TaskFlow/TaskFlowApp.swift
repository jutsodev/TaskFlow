import SwiftUI

@main
struct TaskFlowApp: App {
    @StateObject private var appState = AppState()
    @AppStorage("selectedAppearance") private var selectedAppearance = 0

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.hasCompletedOnboarding {
                    ContentView()
                        .transition(.opacity)
                } else {
                    OnboardingView()
                        .transition(.opacity)
                }
            }
            .environmentObject(appState)
            .animation(.easeInOut(duration: 0.4), value: appState.hasCompletedOnboarding)
            .preferredColorScheme(colorScheme)
        }
    }

    private var colorScheme: ColorScheme? {
        switch selectedAppearance {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }
}
