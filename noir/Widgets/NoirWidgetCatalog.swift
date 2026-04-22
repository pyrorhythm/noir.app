import Foundation

@MainActor
enum NoirWidgetCatalog {
    static func registerDefaults(in registry: WidgetRegistry) {
        registry.register { SpacerWidget() }
        registry.register { SpacesWidget() }
        registry.register { ClockWidget() }
        registry.register { BatteryWidget() }
        registry.register { NetworkWidget() }
        registry.register { SettingsWidget() }
    }

    static var defaultLayout: LayoutConfig {
        LayoutConfig(
            zones: [
                .top: ZoneConfig(widgets: [
                    WidgetConfig(
                        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                        type: "Spacer",
                        size: .small,
                        zone: .top,
                        group: .leading,
                        index: 0,
                        settings: [:]
                    ),
                    WidgetConfig(
                        id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
                        type: "Spaces",
                        size: .large,
                        zone: .top,
                        group: .leading,
                        index: 1,
                        settings: [:]
                    ),
                    WidgetConfig(
                        id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                        type: "Clock",
                        size: .medium,
                        zone: .top,
                        group: .trailing,
                        index: 0,
                        settings: [:]
                    ),
                    WidgetConfig(
                        id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
                        type: "Network",
                        size: .small,
                        zone: .top,
                        group: .trailing,
                        index: 1,
                        settings: [:]
                    ),
                    WidgetConfig(
                        id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
                        type: "Battery",
                        size: .small,
                        zone: .top,
                        group: .trailing,
                        index: 2,
                        settings: [:]
                    ),
                    WidgetConfig(
                        id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
                        type: "Settings",
                        size: .small,
                        zone: .top,
                        group: .trailing,
                        index: 3,
                        settings: [:]
                    ),
                ]),
                .bottom: ZoneConfig(widgets: []),
            ]
        )
    }
}
