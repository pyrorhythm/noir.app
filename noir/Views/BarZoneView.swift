import SwiftUI

struct BarZoneView: View {
    let zone: BarZone
    @Environment(BarManager.self) var barManager
    @Environment(SettingsStore.self) var settings

    var body: some View {
        let appearance = settings.barAppearance

        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .glassEffect(in: .rect(cornerRadius: CGFloat(appearance.cornerRadius)))
                .opacity(appearance.opacity)

            HStack(spacing: barManager.layout.spacing) {
                ForEach(barManager.widgets(for: zone, group: .leading)) { widget in
                    WidgetContainerView(config: widget)
                }

                Spacer()

                ForEach(barManager.widgets(for: zone, group: .trailing)) { widget in
                    WidgetContainerView(config: widget)
                }
            }
            .padding(.horizontal, barManager.layout.horizontalPadding)

            if zone == .top && barManager.hasNotch {
                DynamicNotchView()
                    .frame(width: barManager.notchManager.isExpanded ? nil : barManager.notchWidth)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: CGFloat(appearance.height))
    }
}

#Preview("Top Bar") {
    NoirPreviewEnvironment().inject(
        into: BarZoneView(zone: .top)
            .padding()
            .frame(width: 820)
            .background(.black)
    )
}

#Preview("Bottom Bar Editing") {
    NoirPreviewEnvironment(isEditing: true).inject(
        into: BarZoneView(zone: .bottom)
            .padding()
            .frame(width: 820)
            .background(.black)
    )
}
