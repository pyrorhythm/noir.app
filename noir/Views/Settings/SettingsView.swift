import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            LayoutSettingsView()
                .tabItem { Label("Layout", systemImage: "sidebar.left") }
            WidgetSettingsView()
                .tabItem { Label("Widgets", systemImage: "square.grid.2x2") }
            WMSecuritySettingsView()
                .tabItem { Label("Window Managers", systemImage: "macwindow") }
            AppearanceSettingsView()
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
        }
        .frame(width: 500, height: 400)
    }
}
