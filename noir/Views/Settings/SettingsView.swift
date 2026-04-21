import SwiftUI

struct SettingsView: View {
    @State private var selection: SettingsPage? = .appearance

    var body: some View {
        NavigationSplitView {
            List(SettingsPage.allCases, selection: $selection) { page in
                Label(page.title, systemImage: page.systemImage)
                    .tag(page)
            }
            .listStyle(.sidebar)
            .navigationTitle("Noir")
        } detail: {
            (selection ?? .appearance).content
                .navigationTitle((selection ?? .appearance).title)
        }
        .frame(width: 640, height: 420)
    }
}

private enum SettingsPage: String, CaseIterable, Identifiable, Hashable {
    case appearance
    case layout
    case widgets
    case windowManagers

    var id: Self { self }

    var title: String {
        switch self {
        case .appearance: "Appearance"
        case .layout: "Layout"
        case .widgets: "Widgets"
        case .windowManagers: "Window Managers"
        }
    }

    var systemImage: String {
        switch self {
        case .appearance: "paintbrush"
        case .layout: "sidebar.left"
        case .widgets: "square.grid.2x2"
        case .windowManagers: "macwindow"
        }
    }

    @ViewBuilder
    var content: some View {
        switch self {
        case .appearance:
            AppearanceSettingsView()
        case .layout:
            LayoutSettingsView()
        case .widgets:
            WidgetSettingsView()
        case .windowManagers:
            WMSecuritySettingsView()
        }
    }
}

#Preview("Settings") {
    NoirPreviewEnvironment().inject(
        into: SettingsView()
    )
}
