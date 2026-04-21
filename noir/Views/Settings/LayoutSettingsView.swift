import SwiftUI

struct LayoutSettingsView: View {
    @Environment(BarManager.self) var barManager

    var body: some View {
        Form {
            Section("Bars") {
                Toggle("Edit widgets on bars", isOn: editingBinding)

                ForEach(BarZone.allCases, id: \.self) { zone in
                    LabeledContent(zone.rawValue.capitalized) {
                        Text("\(barManager.widgets(for: zone).count) widgets")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var editingBinding: Binding<Bool> {
        Binding {
            barManager.isEditing
        } set: { isEditing in
            barManager.isEditing = isEditing
        }
    }
}
