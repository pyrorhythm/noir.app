import AppKit
import SwiftUI

@Observable
final class BarManager {
    var zones: [BarZone] = [.top, .bottom]
    var layout: BarLayout = .default
    var isEditing: Bool = false

    let notchManager: NotchManager
    let widgetRegistry: WidgetRegistry

    private var widgetConfigs: [UUID: WidgetConfig] = [:]

    var hasNotch: Bool {
        guard let screen = NSScreen.main else { return false }
        return screen.safeAreaInsets.top > 0
    }

    var notchWidth: CGFloat {
        guard let screen = NSScreen.main, screen.safeAreaInsets.top > 0 else { return 0 }
        return 200
    }

    init(
        notchManager: NotchManager? = nil,
        widgetRegistry: WidgetRegistry = WidgetRegistry()
    ) {
        let detectedNotch: Bool = {
            guard let screen = NSScreen.main else { return false }
            return screen.safeAreaInsets.top > 0
        }()
        self.notchManager = notchManager ?? NotchManager(hasNotch: detectedNotch)
        self.widgetRegistry = widgetRegistry
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
    }

    func removeWidget(_ config: WidgetConfig) {
        widgetConfigs.removeValue(forKey: config.id)
    }

    func moveWidget(_ config: WidgetConfig, from source: BarZone, to dest: BarZone, at index: Int) {
        guard var movedConfig = widgetConfigs[config.id] else { return }
        movedConfig.zone = dest
        movedConfig.index = index
        widgetConfigs[movedConfig.id] = movedConfig
    }
}
