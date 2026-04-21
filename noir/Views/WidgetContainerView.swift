import SwiftUI

struct WidgetContainerView: View {
    let config: WidgetConfig
    @Environment(BarManager.self) var barManager
    @Environment(SettingsStore.self) var settings
    @Environment(WidgetRegistry.self) var registry

    var body: some View {
        Group {
            if let widget = registry.createWidget(ofType: config.type, size: config.size) {
                AnyNoirWidgetView(widget: widget)
                    .frame(height: CGFloat(settings.barAppearance.height) - 4)
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

#Preview("Clock Widget") {
    let config = WidgetConfig(
        id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
        type: "Clock",
        size: .medium,
        zone: .top,
        group: .trailing,
        index: 0,
        settings: [:]
    )

    NoirPreviewEnvironment().inject(
        into: WidgetContainerView(config: config)
            .padding()
            .background(.black)
    )
}

#Preview("Widget Editing") {
    let config = WidgetConfig(
        id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
        type: "Settings",
        size: .small,
        zone: .top,
        group: .trailing,
        index: 0,
        settings: [:]
    )

    NoirPreviewEnvironment(isEditing: true).inject(
        into: WidgetContainerView(config: config)
            .padding()
            .background(.black)
    )
}
