import SwiftUI

struct SettingsWidget: NoirWidget {
    let id = UUID()
    var displayName: String { "Settings" }
    var systemImage: String { "gear" }
    var defaultSize: WidgetSize { .medium }

    var body: some View {
        SettingsWidgetView()
    }
}

private struct SettingsWidgetView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "settings")
        } label: {
            Image(systemName: "gear")
        }
        .buttonStyle(.plain)
    }
}
