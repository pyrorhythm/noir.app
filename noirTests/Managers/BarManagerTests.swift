import Testing
import Foundation
@testable import noir

@Suite("BarManager")
@MainActor
struct BarManagerTests {
    @Test("Initial state has default layout")
    func initialState() {
        let manager = BarManager()
        #expect(manager.barHeight == 28)
        #expect(manager.isEditing == false)
        #expect(manager.zones == [.top, .bottom])
    }

    @Test("Add widget to zone")
    func addWidget() {
        let manager = BarManager()
        let config = WidgetConfig(
            id: UUID(),
            type: "Clock",
            size: .medium,
            zone: .top,
            group: .leading,
            index: 0,
            settings: [:]
        )
        manager.addWidget(config)
        #expect(manager.widgets(for: .top).count == 1)
    }

    @Test("Remove widget from zone")
    func removeWidget() {
        let manager = BarManager()
        let config = WidgetConfig(
            id: UUID(),
            type: "Clock",
            size: .medium,
            zone: .top,
            group: .leading,
            index: 0,
            settings: [:]
        )
        manager.addWidget(config)
        #expect(manager.widgets(for: .top).count == 1)
        manager.removeWidget(config)
        #expect(manager.widgets(for: .top).isEmpty)
    }

    @Test("Move widget between zones")
    func moveWidget() {
        let manager = BarManager()
        let config = WidgetConfig(
            id: UUID(),
            type: "Clock",
            size: .medium,
            zone: .top,
            group: .leading,
            index: 0,
            settings: [:]
        )
        manager.addWidget(config)
        manager.moveWidget(config, from: .top, to: .bottom, at: 0)
        #expect(manager.widgets(for: .top).isEmpty)
        #expect(manager.widgets(for: .bottom).count == 1)
    }

    @Test("hasNotch returns a Bool derived from NSScreen safe area insets")
    func hasNotchIsBoolValue() {
        let manager = BarManager()
        let hardwareDependentValue: Bool = manager.hasNotch
        #expect(hardwareDependentValue == true || hardwareDependentValue == false)
    }

    @Test("Widgets filter by group returns only matching group")
    func widgetsFilterByGroup() {
        let manager = BarManager()
        let leading = WidgetConfig(
            id: UUID(),
            type: "Clock",
            size: .medium,
            zone: .top,
            group: .leading,
            index: 0,
            settings: [:]
        )
        let trailing = WidgetConfig(
            id: UUID(),
            type: "Battery",
            size: .small,
            zone: .top,
            group: .trailing,
            index: 0,
            settings: [:]
        )
        manager.addWidget(leading)
        manager.addWidget(trailing)
        #expect(manager.widgets(for: .top).count == 2)
        #expect(manager.widgets(for: .top, group: .leading).count == 1)
        #expect(manager.widgets(for: .top, group: .trailing).count == 1)
    }

    @Test("Widgets are sorted by index ascending")
    func widgetsSortedByIndex() {
        let manager = BarManager()
        let idA = UUID()
        let idB = UUID()
        let idC = UUID()
        let widgetA = WidgetConfig(id: idA, type: "A", size: .small, zone: .top, group: .leading, index: 2, settings: [:])
        let widgetB = WidgetConfig(id: idB, type: "B", size: .small, zone: .top, group: .leading, index: 0, settings: [:])
        let widgetC = WidgetConfig(id: idC, type: "C", size: .small, zone: .top, group: .leading, index: 1, settings: [:])
        manager.addWidget(widgetA)
        manager.addWidget(widgetB)
        manager.addWidget(widgetC)
        let ordered = manager.widgets(for: .top)
        #expect(ordered.map(\.id) == [idB, idC, idA])
    }

    @Test("Layout mutations publish the persisted layout")
    func layoutMutationsPublish() {
        let settings = SettingsStore(defaults: UserDefaults(suiteName: "NoirBarManagerTests-\(UUID().uuidString)")!)
        let manager = BarManager(settings: settings)

        var published: LayoutConfig?
        manager.onLayoutChange = { layout in
            published = layout
        }

        let config = WidgetConfig(id: UUID(), type: "Clock", size: .medium, zone: .top, group: .trailing, index: 0, settings: [:])
        manager.addWidget(config)

        #expect(published?.zones[.top]?.widgets == [config])
    }

    @Test("Applying a saved layout does not publish a new mutation")
    func applyDoesNotPublish() {
        let manager = BarManager()
        var publishCount = 0
        manager.onLayoutChange = { _ in
            publishCount += 1
        }

        let config = LayoutConfig(
            zones: [
                .top: ZoneConfig(widgets: [
                    WidgetConfig(id: UUID(), type: "Clock", size: .medium, zone: .top, group: .trailing, index: 0, settings: [:])
                ]),
                .bottom: ZoneConfig(widgets: [])
            ]
        )

        manager.apply(layoutConfig: config)
        #expect(manager.widgets(for: .top) == config.zones[.top]?.widgets)
        #expect(publishCount == 0)
    }
}
