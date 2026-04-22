import SwiftUI

struct LayoutSettingsView: View {
    @Environment(BarManager.self) var barManager

    var body: some View {
        Form {
            Section("Bars") {
                Toggle("Edit widgets on bars", isOn: editingBinding)

                LabeledContent("Side Margin") {
                    Slider(value: layoutBinding(\.horizontalMargin), in: 0...240, step: 4) {
                        Text("Side Margin")
                    }
                    .frame(width: 180)
                }

                LabeledContent("Vertical Offset") {
                    Slider(value: layoutBinding(\.verticalOffset), in: -12...12, step: 1) {
                        Text("Vertical Offset")
                    }
                    .frame(width: 180)
                }

                LabeledContent("Widget Spacing") {
                    Slider(value: layoutBinding(\.spacing), in: 0...20, step: 1) {
                        Text("Widget Spacing")
                    }
                    .frame(width: 180)
                }

                ForEach(barManager.zones, id: \.self) { zone in
                    LabeledContent(zone.rawValue.capitalized) {
                        Text("\(barManager.widgets(for: zone).count) widgets")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .controlSize(.small)
    }

    private var editingBinding: Binding<Bool> {
        Binding {
            barManager.isEditing
        } set: { isEditing in
            barManager.isEditing = isEditing
        }
    }

    private func layoutBinding(_ keyPath: WritableKeyPath<BarLayout, CGFloat>) -> Binding<Double> {
        Binding {
            Double(barManager.layout[keyPath: keyPath])
        } set: { value in
            var layout = barManager.layout
            layout[keyPath: keyPath] = CGFloat(value)
            barManager.layout = layout
        }
    }
}
