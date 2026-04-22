import SwiftUI

@main
struct NoirApp: App {
    @State private var coordinator: AppCoordinator

    init() {
        let coordinator = AppCoordinator()
        self._coordinator = State(initialValue: coordinator)
        Task { @MainActor in
            coordinator.start()
        }
    }

    var body: some Scene {
        MenuBarExtra("Noir", systemImage: "circle.fill") {
            MenuBarView()
                .noirEnvironment(coordinator)
        }
        .menuBarExtraStyle(.window)

        WindowGroup(id: "welcome") {
            WelcomeWindowView()
                .noirEnvironment(coordinator)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 560, height: 420)
        .windowResizability(.contentSize)

        Window("Settings", id: "settings") {
            SettingsView()
                .noirEnvironment(coordinator)
        }
        .defaultSize(width: 680, height: 430)
        .windowResizability(.contentSize)
    }
}
