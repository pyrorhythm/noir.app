import Foundation
import SwiftUI
import Testing
@testable import noir

struct TestWidget: NoirWidget {
    let id = UUID()
    var displayName: String { "TestWidget" }
    var systemImage: String { "star" }
    var defaultSize: WidgetSize { .small }
    var body: some View { Image(systemName: "star") }
}

struct AnotherWidget: NoirWidget {
    let id = UUID()
    var displayName: String { "AnotherWidget" }
    var systemImage: String { "circle" }
    var defaultSize: WidgetSize { .medium }
    var body: some View { Image(systemName: "circle") }
}

@Suite("WidgetRegistry")
struct WidgetRegistryTests {
    @Test("Register and create widget by type name")
    func registerAndCreate() {
        let registry = WidgetRegistry()
        registry.register { TestWidget() }

        let widget = registry.createWidget(ofType: "TestWidget", size: .small)
        #expect(widget != nil)
        #expect(widget?.displayName == "TestWidget")
    }

    @Test("Returns nil for unregistered type")
    func unregisteredType() {
        let registry = WidgetRegistry()
        let widget = registry.createWidget(ofType: "Unknown", size: .small)
        #expect(widget == nil)
    }

    @Test("Register multiple widgets")
    func multipleWidgets() {
        let registry = WidgetRegistry()
        registry.register { TestWidget() }
        registry.register { AnotherWidget() }

        let w1 = registry.createWidget(ofType: "TestWidget", size: .small)
        let w2 = registry.createWidget(ofType: "AnotherWidget", size: .medium)
        #expect(w1 != nil)
        #expect(w2 != nil)
    }

    @Test("Create widget with different size")
    func createWithSize() {
        let registry = WidgetRegistry()
        registry.register { TestWidget() }

        let widget = registry.createWidget(ofType: "TestWidget", size: .large)
        #expect(widget != nil)
        #expect(widget?.defaultSize == .small) // defaultSize is per-type, not per-creation
    }
}
