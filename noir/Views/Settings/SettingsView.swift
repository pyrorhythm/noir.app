import SwiftUI

struct SettingsView: View {
    @SceneStorage("settings.selection") private var selection = SettingsPage.appearance

    var body: some View {
        NavigationSplitView {
            List(SettingsPage.allCases, selection: $selection) { page in
                Label(page.title, systemImage: page.systemImage)
                    .tag(page)
            }
            .listStyle(.sidebar)
            .navigationTitle("Noir")
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 220)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(selection.title)
                        .font(.title2.weight(.semibold))

                    selection.content
                }
                .frame(width: 460, alignment: .topLeading)
                .padding(24)
            }
        }
        .frame(width: 680, height: 430)
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
