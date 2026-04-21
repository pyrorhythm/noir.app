import SwiftUI

@MainActor
struct NoirPreviewEnvironment {
    let barManager: BarManager
    let settings: SettingsStore
    let wmDetector: WindowManagerDetector

    init(
        layout: LayoutConfig? = nil,
        isEditing: Bool = false,
        notchPresenter: SystemNotchPresenter? = nil,
        detectedWindowManagerName: String? = "aerospace"
    ) {
        let suiteName = "NoirPreview-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let settings = SettingsStore(defaults: defaults)
        settings.barAppearance = BarAppearance(height: 30, opacity: 0.9, cornerRadius: 8)
        let notchManager = NotchManager(hasNotch: true)
        let barManager = BarManager(settings: settings, notchManager: notchManager)
        let wmDetector = WindowManagerDetector { name in
            detectedWindowManagerName == name
        }

        NoirWidgetCatalog.registerDefaults(in: barManager.widgetRegistry)
        barManager.apply(layoutConfig: layout ?? NoirWidgetCatalog.defaultLayout)
        barManager.isEditing = isEditing

        if let detectedWindowManagerName {
            wmDetector.connectionState = .connected
            wmDetector.detectedWM = PreviewWindowManager(name: detectedWindowManagerName)
        }

        if let notchPresenter {
            notchManager.request(notchPresenter)
        }

        self.barManager = barManager
        self.settings = settings
        self.wmDetector = wmDetector
    }

    func inject<Content: View>(into content: Content) -> some View {
        content
            .noirEnvironment(barManager: barManager, settings: settings, wmDetector: wmDetector)
    }
}

private final class PreviewWindowManager: WindowManagerProtocol, @unchecked Sendable {
    let name: String

    init(name: String) {
        self.name = name
    }

    var isRunning: Bool {
        get async { true }
    }

    func focusWorkspace(_ index: Int) async throws {}
    func moveWindow(toWorkspace index: Int) async throws {}
    func activeWorkspace() async throws -> Int { 1 }
    func workspaceNames() async throws -> [String] { ["1", "2", "3"] }
    func visibleWindows() async throws -> [WindowInfo] { [] }
    var onWorkspaceChange: AsyncStream<Int>? { nil }
}
