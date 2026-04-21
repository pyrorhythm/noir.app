import AppKit
import SwiftUI

@MainActor
@Observable
final class BarManager {
    var zones: [BarZone] = [.top, .bottom]
    var layout: BarLayout = .default
    var isEditing: Bool = false {
        didSet {
            updatePanelInteractivity()
        }
    }

    let notchManager: NotchManager
    let settings: SettingsStore
    let widgetRegistry: WidgetRegistry
    var onLayoutChange: ((LayoutConfig) -> Void)?

    private var widgetConfigs: [UUID: WidgetConfig] = [:]
    private var panels: [BarZone: NSPanel] = [:]
    private var observationStarted = false
    private var displayObserver: NSObjectProtocol?
    private var isApplyingLayout = false

    var barHeight: CGFloat {
        CGFloat(settings.barAppearance.height)
    }

    var hasNotch: Bool {
        guard let screen = targetScreen else { return false }
        return screen.safeAreaInsets.top > 0
    }

    var notchWidth: CGFloat {
        guard let screen = targetScreen, screen.safeAreaInsets.top > 0 else { return 0 }
        return 200
    }

    private var targetScreen: NSScreen? {
        NSScreen.main ?? NSScreen.screens.first
    }

    init(
        settings: SettingsStore? = nil,
        notchManager: NotchManager? = nil,
        widgetRegistry: WidgetRegistry? = nil
    ) {
        let detectedNotch: Bool = {
            guard let screen = NSScreen.main else { return false }
            return screen.safeAreaInsets.top > 0
        }()
        self.settings = settings ?? SettingsStore()
        self.notchManager = notchManager ?? NotchManager(hasNotch: detectedNotch)
        self.widgetRegistry = widgetRegistry ?? WidgetRegistry()
        startObservingSettings()
    }

    func widgets(for zone: BarZone, group: WidgetGroup? = nil) -> [WidgetConfig] {
        let zoneWidgets = widgetConfigs.values
            .filter { $0.zone == zone }
            .sorted { $0.index < $1.index }
        if let group {
            return zoneWidgets.filter { $0.group == group }
        }
        return zoneWidgets
    }

    func addWidget(_ config: WidgetConfig) {
        widgetConfigs[config.id] = config
        publishLayoutChange()
    }

    func removeWidget(_ config: WidgetConfig) {
        widgetConfigs.removeValue(forKey: config.id)
        publishLayoutChange()
    }

    func moveWidget(_ config: WidgetConfig, from source: BarZone, to dest: BarZone, at index: Int) {
        guard var movedConfig = widgetConfigs[config.id] else { return }
        movedConfig.zone = dest
        movedConfig.index = index
        widgetConfigs[movedConfig.id] = movedConfig
        publishLayoutChange()
    }

    func apply(layoutConfig: LayoutConfig) {
        isApplyingLayout = true
        widgetConfigs.removeAll()
        for zone in BarZone.allCases {
            for widget in layoutConfig.zones[zone]?.widgets ?? [] {
                widgetConfigs[widget.id] = widget
            }
        }
        isApplyingLayout = false
    }

    func createPanels() {
        guard let screen = targetScreen else { return }
        startObservingDisplays()

        for zone in zones {
            if panels[zone] != nil { continue }

            let panelRect = frame(for: zone, on: screen)

            let panel = NSPanel.makeBarPanel(contentRect: panelRect)
            let hostingController = NSHostingController(
                rootView: BarZoneView(zone: zone)
                    .environment(self)
                    .environment(settings)
                    .environment(notchManager)
                    .environment(widgetRegistry)
            )
            panel.contentViewController = hostingController
            panel.setFrame(panelRect, display: true)
            panel.ignoresMouseEvents = !isEditing
            panel.orderFrontRegardless()
            panels[zone] = panel
        }
    }

    func destroyPanels() {
        for (_, panel) in panels {
            panel.close()
        }
        panels.removeAll()
        if let displayObserver {
            NotificationCenter.default.removeObserver(displayObserver)
            self.displayObserver = nil
        }
    }

    private func startObservingSettings() {
        guard !observationStarted else { return }
        observationStarted = true
        observeSettingsChanges()
    }

    private func observeSettingsChanges() {
        withObservationTracking {
            _ = settings.barAppearance
        } onChange: {
            Task { @MainActor in
                self.updatePanelFrames()
                self.observeSettingsChanges()
            }
        }
    }

    private func updatePanelFrames() {
        guard let screen = targetScreen else { return }
        for (zone, panel) in panels {
            panel.setFrame(frame(for: zone, on: screen), display: true)
        }
    }

    private func updatePanelInteractivity() {
        for panel in panels.values {
            panel.ignoresMouseEvents = !isEditing
        }
    }

    private func startObservingDisplays() {
        guard displayObserver == nil else { return }
        displayObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updatePanelFrames()
            }
        }
    }

    private func frame(for zone: BarZone, on screen: NSScreen) -> NSRect {
        let visibleFrame = screen.visibleFrame
        let height = barHeight
        switch zone {
        case .top:
            return NSRect(
                x: visibleFrame.minX,
                y: visibleFrame.maxY - height,
                width: visibleFrame.width,
                height: height
            )
        case .bottom:
            return NSRect(
                x: visibleFrame.minX,
                y: visibleFrame.minY,
                width: visibleFrame.width,
                height: height
            )
        }
    }

    private func currentLayoutConfig() -> LayoutConfig {
        var zones: [BarZone: ZoneConfig] = [:]
        for zone in BarZone.allCases {
            zones[zone] = ZoneConfig(widgets: widgets(for: zone))
        }
        return LayoutConfig(zones: zones)
    }

    private func publishLayoutChange() {
        guard !isApplyingLayout else { return }
        let config = currentLayoutConfig()
        onLayoutChange?(config)
    }
}
