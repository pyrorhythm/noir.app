import SwiftUI

struct SettingsWidget: NoirWidget {
    let id = UUID()
    var displayName: String { "Settings" }
    var systemImage: String { "gear" }
    var defaultSize: WidgetSize { .small }

    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button {
            NSApp.activate(ignoringOtherApps: true)
            openSettings()
        } label: {
            Image(systemName: "gear")
        }
        .buttonStyle(.plain)
    }
}