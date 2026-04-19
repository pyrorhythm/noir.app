import SwiftUI

struct WidgetSettingsView: View {
    @Environment(SettingsStore.self) var settings

    var body: some View {
        Text("Widget settings — enable/disable and configure widgets coming soon")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
