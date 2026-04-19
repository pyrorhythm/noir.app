import Testing
import Foundation
@testable import noir

@Suite("Smoke Tests")
struct SmokeTests {
    @Test("BarManager creates with default state")
    func barManagerDefaults() {
        let manager = BarManager()
        #expect(manager.zones == [.top, .bottom])
        #expect(manager.isEditing == false)
        #expect(manager.layout.barHeight == 28)
    }

    @Test("WidgetRegistry registers and creates widgets")
    func widgetRegistry() {
        let registry = WidgetRegistry()
        registry.register { SpacerWidget() }
        registry.register { ClockWidget() }

        let spacer = registry.createWidget(ofType: "Spacer", size: .small)
        #expect(spacer != nil)

        let clock = registry.createWidget(ofType: "Clock", size: .medium)
        #expect(clock != nil)
    }

    @Test("NotchManager initial state")
    func notchManagerInitialState() {
        let manager = NotchManager(hasNotch: true)
        #expect(manager.isExpanded == false)
        #expect(manager.activePresenter == nil)
    }

    @Test("LayoutStore round-trip with default config")
    func layoutStoreRoundTrip() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("NoirSmokeTest-\(UUID().uuidString)")
        let store = LayoutStore(directory: dir)
        let config = LayoutConfig.default
        try store.save(config)
        let loaded = try store.load()
        #expect(loaded == config)
    }

    @Test("WindowManagerDetector initial state")
    func wmDetectorInitialState() {
        let detector = WindowManagerDetector()
        #expect(detector.connectionState == .disconnected)
        #expect(detector.detectedWM == nil)
    }
}
