import SwiftUI

struct WidgetSettingsView: View {
    @Environment(WidgetRegistry.self) var registry

    var body: some View {
        List(registry.registeredWidgets) { widget in
            HStack(spacing: 12) {
                Image(systemName: widget.systemImage)
                    .foregroundStyle(.secondary)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 2) {
                    Text(widget.displayName)
                    Text("Default size: \(widget.defaultSize.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
