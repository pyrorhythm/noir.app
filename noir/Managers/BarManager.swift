import AppKit
import SwiftUI

@MainActor
@Observable
final class BarManager {
    var zones: [BarZone] = [.top]
    var isEditing: Bool = false {
        didSet {
            updateEditPanelVisibility()
        }
    }

    let notchManager: NotchManager
    let settings: SettingsStore
    let widgetRegistry: WidgetRegistry
    var onLayoutChange: ((LayoutConfig) -> Void)?

    private var widgetConfigs: [UUID: WidgetConfig] = [:]
    private var panel: NSPanel?
    private var editPanel: NSPanel?
    private var wmDetector: WindowManagerDetector?
    private var observationStarted = false
    private var displayObserver: NSObjectProtocol?
    private var isApplyingLayout = false

    var barHeight: CGFloat {
        CGFloat(settings.barAppearance.height)
    }

    var barPanelHeight: CGFloat {
        guard let screen = targetScreen else {
            return barHeight + barGlassBackdropDepth
        }
        return panelHeight(on: screen, height: barHeight)
    }

    var barGlassBackdropDepth: CGFloat {
        34
    }

    var barContentTopInset: CGFloat {
        guard let screen = targetScreen else { return 0 }
        return contentTopInset(on: screen, height: barHeight)
    }

    var layout: BarLayout {
        get { settings.barLayout }
        set { settings.barLayout = newValue }
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

    func addWidget(type: String, group: WidgetGroup) {
        let descriptor = widgetRegistry.registeredWidgets.first { $0.typeName == type }
        let config = WidgetConfig(
            id: UUID(),
            type: type,
            size: descriptor?.defaultSize ?? .medium,
            zone: .top,
            group: group,
            index: widgets(for: .top, group: group).count,
            settings: [:]
        )
        addWidget(config)
    }

    func removeWidget(_ config: WidgetConfig) {
        widgetConfigs.removeValue(forKey: config.id)
        normalizeIndices(in: config.zone, group: config.group)
        publishLayoutChange()
    }

    func moveWidget(_ config: WidgetConfig, from source: BarZone, to dest: BarZone, at index: Int) {
        guard var movedConfig = widgetConfigs[config.id] else { return }
        movedConfig.zone = dest
        movedConfig.index = index
        widgetConfigs[movedConfig.id] = movedConfig
        normalizeIndices(in: source, group: config.group)
        normalizeIndices(in: dest, group: movedConfig.group)
        publishLayoutChange()
    }

    func moveWidget(_ id: UUID, to group: WidgetGroup, at index: Int) {
        guard var movedConfig = widgetConfigs[id] else { return }
        let sourceGroup = movedConfig.group
        movedConfig.zone = .top
        movedConfig.group = group
        movedConfig.index = index
        widgetConfigs[id] = movedConfig
        normalizeIndices(in: .top, group: sourceGroup)
        normalizeIndices(in: .top, group: group)
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

    func createPanels(wmDetector: WindowManagerDetector? = nil) {
        guard let screen = targetScreen else { return }
        guard panel == nil else { return }
        self.wmDetector = wmDetector
        startObservingDisplays()

        let panelRect = frame(on: screen)
        let detector = wmDetector ?? WindowManagerDetector()

        let panel = NSPanel.makeBarPanel(contentRect: panelRect)
        let hostingController = NSHostingController(
            rootView: BarZoneView(zone: .top)
                .environment(self)
                .environment(settings)
                .environment(detector)
                .environment(notchManager)
                .environment(widgetRegistry)
        )
        panel.contentViewController = hostingController
        panel.setFrame(panelRect, display: true)
        panel.orderFrontRegardless()
        self.panel = panel
    }

    func destroyPanels() {
        panel?.close()
        panel = nil
        editPanel?.close()
        editPanel = nil
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
            _ = settings.barLayout
        } onChange: {
            Task { @MainActor in
                self.updatePanelFrames()
                self.observeSettingsChanges()
            }
        }
    }

    private func updatePanelFrames() {
        guard let screen = targetScreen else { return }
        panel?.setFrame(frame(on: screen), display: true)
        editPanel?.setFrame(editFrame(on: screen), display: true)
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

    private func frame(on screen: NSScreen) -> NSRect {
        let height = barHeight
        let panelHeight = panelHeight(on: screen, height: height)
        return NSRect(
            x: screen.frame.minX + layout.horizontalMargin,
            y: screen.frame.maxY - panelHeight,
            width: max(240, screen.frame.width - layout.horizontalMargin * 2),
            height: panelHeight
        )
    }

    private func editFrame(on screen: NSScreen) -> NSRect {
        let width: CGFloat = min(760, max(520, screen.visibleFrame.width - 80))
        let height: CGFloat = 330
        let barFrame = frame(on: screen)
        let x = screen.visibleFrame.midX - width / 2
        let y = max(screen.visibleFrame.minY + 24, barFrame.minY - height - 16)
        return NSRect(x: x, y: y, width: width, height: height)
    }

    private func reservedTopInset(on screen: NSScreen, height: CGFloat) -> CGFloat {
        let menuBarHeight = screen.frame.maxY - screen.visibleFrame.maxY
        let reservedTopHeight = max(menuBarHeight, screen.safeAreaInsets.top)
        return max(0, (reservedTopHeight - height) / 2)
    }

    private func contentTopInset(on screen: NSScreen, height: CGFloat) -> CGFloat {
        max(0, reservedTopInset(on: screen, height: height) + layout.verticalOffset)
    }

    private func panelHeight(on screen: NSScreen, height: CGFloat) -> CGFloat {
        contentTopInset(on: screen, height: height) + height + barGlassBackdropDepth
    }

    private func currentLayoutConfig() -> LayoutConfig {
        var zones: [BarZone: ZoneConfig] = [:]
        for zone in self.zones {
            zones[zone] = ZoneConfig(widgets: widgets(for: zone))
        }
        return LayoutConfig(zones: zones)
    }

    private func publishLayoutChange() {
        guard !isApplyingLayout else { return }
        let config = currentLayoutConfig()
        onLayoutChange?(config)
    }

    private func updateEditPanelVisibility() {
        if isEditing {
            createEditPanel()
        } else {
            editPanel?.close()
            editPanel = nil
        }
    }

    private func createEditPanel() {
        guard editPanel == nil, let screen = targetScreen else { return }
        let editPanel = NSPanel.makeBarEditPanel(contentRect: editFrame(on: screen))
        editPanel.contentViewController = NSHostingController(
            rootView: WidgetEditPanelView()
                .environment(self)
                .environment(settings)
                .environment(notchManager)
                .environment(widgetRegistry)
        )
        editPanel.orderFrontRegardless()
        self.editPanel = editPanel
    }

    private func normalizeIndices(in zone: BarZone, group: WidgetGroup) {
        for (index, widget) in widgets(for: zone, group: group).enumerated() {
            var normalized = widget
            normalized.index = index
            widgetConfigs[widget.id] = normalized
        }
    }
}
