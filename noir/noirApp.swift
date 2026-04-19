import SwiftUI

@main
struct NoirApp: App {
    @State private var barManager: BarManager
    @State private var settings = SettingsStore()
    @State private var wmDetector = WindowManagerDetector()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        let manager = BarManager()
        manager.widgetRegistry.register { SpacerWidget() }
        manager.widgetRegistry.register { ClockWidget() }
        self._barManager = State(initialValue: manager)
    }

    var body: some Scene {
        MenuBarExtra("Noir", systemImage: "circle.fill") {
            MenuBarExtraContent()
                .environment(barManager)
                .environment(settings)
                .environment(wmDetector)
        }
        .menuBarExtraStyle(.window)

        WindowGroup(id: "welcome") {
            WelcomeWindowView()
                .environment(barManager)
                .environment(settings)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 560, height: 420)
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
                .environment(barManager)
                .environment(settings)
                .environment(wmDetector)
        }
    }
}

struct MenuBarExtraContent: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        MenuBarView()
            .task {
                if !hasCompletedOnboarding {
                    openWindow(id: "welcome")
                }
            }
    }
}
