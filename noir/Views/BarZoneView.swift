import SwiftUI

struct BarZoneView: View {
    let zone: BarZone
    @Environment(BarManager.self) var barManager
    @Environment(SettingsStore.self) var settings

    var body: some View {
        let appearance = settings.barAppearance
        let height = CGFloat(appearance.height)

        HStack(spacing: 0) {
            widgetGroup(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            Color.clear
                .frame(width: notchGapWidth)
                .allowsHitTesting(false)

            widgetGroup(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(height: height)
        .padding(.horizontal, 8)
    }

    private var notchGapWidth: CGFloat {
        zone == .top && barManager.hasNotch ? barManager.notchWidth : 0
    }

    private func widgetGroup(_ group: WidgetGroup) -> some View {
        HStack(spacing: barManager.layout.spacing) {
            ForEach(barManager.widgets(for: zone, group: group)) { widget in
                WidgetContainerView(config: widget)
            }
        }
        .padding(.horizontal, barManager.layout.horizontalPadding)
        .frame(height: CGFloat(settings.barAppearance.height))
        .barGlass(appearance: settings.barAppearance)
    }
}

private extension View {
    func barGlass(appearance: BarAppearance) -> some View {
        let radius = CGFloat(appearance.cornerRadius)

        return background {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(.clear)
                .glassEffect(.clear, in: .rect(cornerRadius: radius))
                .opacity(appearance.opacity)
                .shadow(color: .black.opacity(0.18), radius: 10, y: 1)
        }
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
