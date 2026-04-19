import SwiftUI

@main
struct NoirApp: App {
    @State private var barManager: BarManager
    @State private var settings = SettingsStore()
    @State private var wmDetector = WindowManagerDetector()

    init() {
        let manager = BarManager()
        manager.widgetRegistry.register { SpacerWidget() }
        manager.widgetRegistry.register { ClockWidget() }
        self._barManager = State(initialValue: manager)
    }

    var body: some Scene {
        Settings {
            SettingsView()
                .environment(barManager)
                .environment(settings)
                .environment(wmDetector)
        }
    }
}
