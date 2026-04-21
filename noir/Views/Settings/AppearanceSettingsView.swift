import SwiftUI

struct AppearanceSettingsView: View {
    @Environment(SettingsStore.self) var settings

    var body: some View {
        Form {
            Section("Bar") {
                ForEach(BarAppearance.controls) { control in
                    LabeledContent {
                        HStack {
                            Slider(value: binding(for: control), in: control.range, step: control.step)
                            Text(settings.barAppearance[keyPath: control.value], format: control.format)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                                .frame(width: 48, alignment: .trailing)
                        }
                    } label: {
                        Label(control.title, systemImage: control.systemImage)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private func binding(for control: BarAppearanceControl) -> Binding<Double> {
        Binding {
            settings.barAppearance[keyPath: control.value]
        } set: { newValue in
            var appearance = settings.barAppearance
            appearance[keyPath: control.value] = newValue
            settings.barAppearance = appearance
        }
    }
}

#Preview("Appearance Settings") {
    NoirPreviewEnvironment().inject(
        into: AppearanceSettingsView()
            .frame(width: 420, height: 240)
    )
}
