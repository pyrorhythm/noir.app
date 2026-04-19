import SwiftUI

@Observable
final class SettingsStore {
    var barHeight: CGFloat = 28
    var barOpacity: Double = 1.0
    var selectedWM: String? = nil
    var widgetConfigs: [UUID: WidgetConfig] = [:]
    var layoutConfig: LayoutConfig = .default
}
