import SwiftUI

struct WidgetDescriptor: Identifiable, Equatable {
    var id: String { typeName }
    let typeName: String
    let displayName: String
    let systemImage: String
    let defaultSize: WidgetSize
}

@MainActor
@Observable
final class WidgetRegistry {
    private var widgetFactories: [String: () -> any NoirWidget] = [:]
    private var widgetDescriptors: [String: WidgetDescriptor] = [:]

    func register(_ factory: @escaping () -> any NoirWidget) {
        let widget = factory()
        widgetFactories[widget.displayName] = factory
        widgetDescriptors[widget.displayName] = WidgetDescriptor(
            typeName: widget.displayName,
            displayName: widget.displayName,
            systemImage: widget.systemImage,
            defaultSize: widget.defaultSize
        )
    }

    func createWidget(ofType typeName: String, size: WidgetSize) -> (any NoirWidget)? {
        widgetFactories[typeName]?()
    }

    var registeredTypeNames: [String] {
        widgetFactories.keys.sorted()
    }

    var registeredWidgets: [WidgetDescriptor] {
        widgetDescriptors.values.sorted { $0.displayName < $1.displayName }
    }
}
