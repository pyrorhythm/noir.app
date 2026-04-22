import SwiftUI
import UniformTypeIdentifiers

struct WidgetEditPanelView: View {
    @Environment(BarManager.self) private var barManager
    @Environment(WidgetRegistry.self) private var registry

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            HStack(alignment: .top, spacing: 18) {
                palette
                    .frame(width: 210)

                VStack(spacing: 14) {
                    editLane("Left", group: .leading)
                    editLane("Right", group: .trailing)
                }
            }
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var header: some View {
        HStack {
            Label("Edit Bar", systemImage: "slider.horizontal.3")
                .font(.headline)

            Spacer()

            Button("Done") {
                barManager.isEditing = false
            }
            .keyboardShortcut(.defaultAction)
        }
    }

    private var palette: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Widgets")
                .font(.subheadline.weight(.semibold))

            ForEach(registry.registeredWidgets) { widget in
                HStack(spacing: 10) {
                    Image(systemName: widget.systemImage)
                        .frame(width: 18)
                        .foregroundStyle(.secondary)

                    Text(widget.displayName)
                        .lineLimit(1)

                    Spacer()

                    Button {
                        barManager.addWidget(type: widget.typeName, group: .trailing)
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .frame(height: 34)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .draggable(widget.typeName)
            }
        }
    }

    private func editLane(_ title: String, group: WidgetGroup) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 8) {
                let widgets = barManager.widgets(for: .top, group: group)
                if widgets.isEmpty {
                    Text("Drop widgets here")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 52)
                } else {
                    ForEach(widgets) { widget in
                        EditWidgetBlock(config: widget)
                            .onDrop(
                                of: [.text],
                                delegate: WidgetDropDelegate(
                                    barManager: barManager,
                                    targetGroup: group,
                                    targetIndex: widget.index
                                )
                            )
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .onDrop(
                of: [.text],
                delegate: WidgetDropDelegate(
                    barManager: barManager,
                    targetGroup: group,
                    targetIndex: barManager.widgets(for: .top, group: group).count
                )
            )
        }
    }
}

private struct EditWidgetBlock: View {
    @Environment(WidgetRegistry.self) private var registry
    @Environment(BarManager.self) private var barManager

    let config: WidgetConfig

    var body: some View {
        let descriptor = registry.registeredWidgets.first { $0.typeName == config.type }

        HStack(spacing: 8) {
            Image(systemName: descriptor?.systemImage ?? "square")
                .frame(width: 18)

            Text(config.type)
                .font(.caption.weight(.medium))
                .lineLimit(1)

            Button {
                barManager.removeWidget(config)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .frame(height: 38)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 0.75)
        }
        .draggable(config.id.uuidString)
    }
}

private struct WidgetDropDelegate: DropDelegate {
    let barManager: BarManager
    let targetGroup: WidgetGroup
    let targetIndex: Int

    func performDrop(info: DropInfo) -> Bool {
        guard let provider = info.itemProviders(for: [.text]).first else { return false }

        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
            let text: String?
            if let data = item as? Data {
                text = String(data: data, encoding: .utf8)
            } else {
                text = item as? String
            }

            guard let text else { return }
            Task { @MainActor in
                if let id = UUID(uuidString: text) {
                    barManager.moveWidget(id, to: targetGroup, at: targetIndex)
                } else {
                    barManager.addWidget(type: text, group: targetGroup)
                }
            }
        }

        return true
    }
}
