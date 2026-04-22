import SwiftUI

struct WidgetContainerView: View {
    let config: WidgetConfig
    @Environment(BarManager.self) var barManager
    @Environment(SettingsStore.self) var settings
    @Environment(WidgetRegistry.self) var registry
    @State private var isPopoverPresented = false

    var body: some View {
        Group {
            if let widget = registry.createWidget(ofType: config.type, size: config.size) {
                widgetView(widget)
            } else {
                Image(systemName: "questionmark.square")
                    .foregroundStyle(.secondary)
            }
        }
        .if(barManager.isEditing) { view in
            view
                .padding(.horizontal, 4)
                .overlay {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(.secondary.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }
        }
    }

    @ViewBuilder
    private func widgetView(_ widget: any NoirWidget) -> some View {
        let content = AnyNoirWidgetView(widget: widget)
            .frame(height: CGFloat(settings.barAppearance.height) - 4)

        if let popover = widget.popover {
            content
                .contentShape(Rectangle())
                .onTapGesture {
                    isPopoverPresented.toggle()
                }
                .popover(isPresented: $isPopoverPresented) {
                    popover
                }
        } else {
            content
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
