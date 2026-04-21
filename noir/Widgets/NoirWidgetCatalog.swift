import Foundation

@MainActor
enum NoirWidgetCatalog {
    static func registerDefaults(in registry: WidgetRegistry) {
        registry.register { SpacerWidget() }
        registry.register { ClockWidget() }
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
                        id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                        type: "Clock",
                        size: .medium,
                        zone: .top,
                        group: .trailing,
                        index: 0,
                        settings: [:]
                    ),
                    WidgetConfig(
                        id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
                        type: "Settings",
                        size: .small,
                        zone: .top,
                        group: .trailing,
                        index: 1,
                        settings: [:]
                    ),
                ]),
                .bottom: ZoneConfig(widgets: []),
            ]
        )
    }
}
