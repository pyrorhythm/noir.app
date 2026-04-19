import SwiftUI

struct WidgetContainerView: View {
    let config: WidgetConfig
    @Environment(BarManager.self) var barManager
    @Environment(WidgetRegistry.self) var registry

    var body: some View {
        Group {
            if let widget = registry.createWidget(ofType: config.type, size: config.size) {
                AnyNoirWidgetView(widget: widget)
                    .frame(height: barManager.layout.barHeight - 4)
            } else {
                Image(systemName: "questionmark.square")
                    .foregroundStyle(.secondary)
            }
        }
        .if(barManager.isEditing) { view in
            view.overlay(alignment: .topTrailing) {
                Button {
                    barManager.removeWidget(config)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct AnyNoirWidgetView: View {
    let widget: any NoirWidget
    
    var body: some View {
        unbox(widget)
    }
    
    private func unbox(_ widget: some NoirWidget) -> AnyView {
        AnyView(widget.body)
    }
}

extension View {
    @ViewBuilder
    func `if`(_ condition: Bool, transform: (Self) -> some View) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
