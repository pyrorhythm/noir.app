import SwiftUI

extension View {
    @MainActor
    func noirEnvironment(_ coordinator: AppCoordinator) -> some View {
        noirEnvironment(
            barManager: coordinator.barManager,
            settings: coordinator.settings,
            wmDetector: coordinator.wmDetector
        )
        .environment(coordinator)
    }

    @MainActor
    func noirEnvironment(
        barManager: BarManager,
        settings: SettingsStore,
        wmDetector: WindowManagerDetector
    ) -> some View {
        self
            .environment(barManager)
            .environment(settings)
            .environment(wmDetector)
            .environment(barManager.notchManager)
            .environment(barManager.widgetRegistry)
    }
}
