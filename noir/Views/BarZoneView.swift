import SwiftUI

struct BarZoneView: View {
    let zone: BarZone
    @Environment(BarManager.self) var barManager

    var body: some View {
        HStack(spacing: barManager.layout.spacing) {
            ForEach(barManager.widgets(for: zone, group: .leading)) { widget in
                WidgetContainerView(config: widget)
            }

            if zone == .top && barManager.hasNotch {
                DynamicNotchView()
                    .frame(width: barManager.notchManager.isExpanded ? nil : barManager.notchWidth)
            }

            ForEach(barManager.widgets(for: zone, group: .trailing)) { widget in
                WidgetContainerView(config: widget)
            }
        }
        .padding(.horizontal, barManager.layout.horizontalPadding)
        .glassEffect(in: .rect(cornerRadius: barManager.layout.cornerRadius))
        .frame(maxWidth: .infinity)
        .frame(height: barManager.layout.barHeight)
    }
}
