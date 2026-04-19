import SwiftUI

@Observable
final class WidgetRegistry {
    private var widgetFactories: [String: () -> any NoirWidget] = [:]

    func register(_ factory: @escaping () -> any NoirWidget) {
        let widget = factory()
        widgetFactories[widget.displayName] = factory
    }

    func createWidget(ofType typeName: String, size: WidgetSize) -> (any NoirWidget)? {
        widgetFactories[typeName]?()
    }

    var registeredTypeNames: [String] {
        widgetFactories.keys.sorted()
    }
}
