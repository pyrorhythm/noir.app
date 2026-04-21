import Foundation
import Testing
@testable import noir

@Suite("LayoutStore")
@MainActor
struct LayoutStoreTests {
    @Test("Save and load layout config round-trip")
    func roundTrip() throws {
        let store = LayoutStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent("NoirTest-\(UUID().uuidString)"))
        let config = LayoutConfig(
            zones: [
                .top: ZoneConfig(widgets: [
                    WidgetConfig(id: UUID(), type: "Clock", size: .medium, zone: .top, group: .leading, index: 0, settings: [:]),
                    WidgetConfig(id: UUID(), type: "Wifi", size: .small, zone: .top, group: .trailing, index: 0, settings: [:]),
                ]),
                .bottom: ZoneConfig(widgets: [])
            ]
        )

        try store.save(config)
        let loaded = try store.load()

        #expect(loaded.zones[.top]?.widgets.count == 2)
        #expect(loaded.zones[.top]?.widgets[0].type == "Clock")
        #expect(loaded.zones[.bottom]?.widgets.isEmpty == true)
    }

    @Test("Load returns default when no file exists")
    func loadDefault() throws {
        let store = LayoutStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent("NoirTest-Missing-\(UUID().uuidString)"))
        let config = try store.load()
        #expect(config.zones[.top]?.widgets.isEmpty == true)
        #expect(config.zones[.bottom]?.widgets.isEmpty == true)
    }

    @Test("Save creates directory if needed")
    func createsDirectory() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("NoirTest-NewDir-\(UUID().uuidString)")
        let store = LayoutStore(directory: dir)
        let config = LayoutConfig.default
        try store.save(config)
        #expect(FileManager.default.fileExists(atPath: dir.appendingPathComponent("layout.json").path))
    }
}