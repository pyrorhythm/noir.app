import AppKit
import SwiftUI

@MainActor
@Observable
final class AppCoordinator {
    let barManager: BarManager
    let settings: SettingsStore
    let wmDetector: WindowManagerDetector

    private let layoutStore: LayoutStore
    private let mediaKeyMonitor: MediaKeyMonitor
    private var welcomeWindow: NSWindow?
    private var welcomeDelegate: WelcomeWindowDelegate?
    private var hasStarted = false

    init(
        barManager: BarManager? = nil,
        settings: SettingsStore? = nil,
        wmDetector: WindowManagerDetector? = nil,
        layoutStore: LayoutStore? = nil,
        mediaKeyMonitor: MediaKeyMonitor? = nil
    ) {
        if let barManager {
            self.barManager = barManager
            self.settings = settings ?? barManager.settings
        } else {
            let resolvedSettings = settings ?? SettingsStore()
            self.settings = resolvedSettings
            self.barManager = BarManager(settings: resolvedSettings)
        }
        self.wmDetector = wmDetector ?? WindowManagerDetector()
        self.layoutStore = layoutStore ?? LayoutStore()
        self.mediaKeyMonitor = mediaKeyMonitor ?? MediaKeyMonitor()

        NoirWidgetCatalog.registerDefaults(in: self.barManager.widgetRegistry)
        loadLayout()
        wirePersistence()
        wireMediaKeys()
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true

        barManager.createPanels(wmDetector: wmDetector)
        mediaKeyMonitor.start()

        Task {
            await wmDetector.detect()
        }

        showWelcomeIfNeeded()
    }

    func stop() {
        mediaKeyMonitor.stop()
        barManager.destroyPanels()
    }

    private func loadLayout() {
        let storedLayout = (try? layoutStore.load()) ?? .default
        let layout = storedLayout.isEmpty ? NoirWidgetCatalog.defaultLayout : storedLayout.withSpacesWidgetIfMissing()
        barManager.apply(layoutConfig: layout)
        if layout != storedLayout {
            try? layoutStore.save(layout)
        }
    }

    private func wirePersistence() {
        barManager.onLayoutChange = { [weak self] layout in
            guard let self else { return }
            try? self.layoutStore.save(layout)
        }
    }

    private func wireMediaKeys() {
        mediaKeyMonitor.onVolumeChange = { [weak self] delta in
            Task { @MainActor in
                self?.barManager.notchManager.request(SystemNotchPresenter(kind: .volume, value: delta))
            }
        }
        mediaKeyMonitor.onBrightnessChange = { [weak self] delta in
            Task { @MainActor in
                self?.barManager.notchManager.request(SystemNotchPresenter(kind: .brightness, value: delta))
            }
        }
    }

    private func showWelcomeIfNeeded() {
        guard !ProcessInfo.processInfo.arguments.contains("--noir-ui-testing-disable-onboarding") else { return }
        guard !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding"),
              welcomeWindow == nil
        else { return }

        let rootView = WelcomeWindowView { [weak self] in
            self?.closeWelcomeWindow()
        }
        .noirEnvironment(self)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 420),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to Noir"
        window.contentViewController = NSHostingController(rootView: rootView)
        window.center()
        window.isReleasedWhenClosed = false
        let delegate = WelcomeWindowDelegate { [weak self] in
            self?.welcomeWindow = nil
            self?.welcomeDelegate = nil
        }
        welcomeDelegate = delegate
        window.delegate = delegate
        welcomeWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func closeWelcomeWindow() {
        welcomeWindow?.close()
        welcomeWindow = nil
        welcomeDelegate = nil
    }

}

private final class WelcomeWindowDelegate: NSObject, NSWindowDelegate {
    private let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}

private extension LayoutConfig {
    var isEmpty: Bool {
        zones.values.allSatisfy { $0.widgets.isEmpty }
    }

    func withSpacesWidgetIfMissing() -> LayoutConfig {
        guard zones.values.flatMap(\.widgets).contains(where: { $0.type == "Spaces" }) == false else {
            return self
        }

        var layout = self
        var top = layout.zones[.top] ?? ZoneConfig(widgets: [])
        let leadingIndex = top.widgets.filter { $0.group == .leading }.count
        top.widgets.append(
            WidgetConfig(
                id: UUID(uuidString: "44444444-4444-4444-4444-444444444444") ?? UUID(),
                type: "Spaces",
                size: .large,
                zone: .top,
                group: .leading,
                index: leadingIndex,
                settings: [:]
            )
        )
        layout.zones[.top] = top
        return layout
    }
}
