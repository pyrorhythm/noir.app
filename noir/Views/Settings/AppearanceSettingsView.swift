import SwiftUI

struct AppearanceSettingsView: View {
    @Environment(SettingsStore.self) var settings

    var body: some View {
        Form {
            Section("Bar") {
                Slider(value: Bindable(settings).barHeight, in: 24...36, step: 2) {
                    Text("Bar Height")
                }
                Slider(value: Bindable(settings).barOpacity, in: 0.5...1.0, step: 0.05) {
                    Text("Opacity")
                }
            }
        }
        .formStyle(.grouped)
    }
}
