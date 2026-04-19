import SwiftUI

struct LayoutSettingsView: View {
    @Environment(SettingsStore.self) var settings

    var body: some View {
        Text("Layout settings — drag and drop widget arrangement coming soon")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
