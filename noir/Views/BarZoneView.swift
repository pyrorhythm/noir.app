import SwiftUI

struct BarZoneView: View {
    let zone: BarZone
    @Environment(BarManager.self) var barManager
    @Environment(SettingsStore.self) var settings

    var body: some View {
        let appearance = settings.barAppearance
        let height = CGFloat(appearance.height)

        ZStack(alignment: .top) {
//            BarGlassBackdrop()
//                .frame(height: barManager.barPanelHeight)
//                .allowsHitTesting(false)

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
            .padding(.top, barManager.barContentTopInset)
        }
        .frame(height: barManager.barPanelHeight, alignment: .top)
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

private struct BarGlassBackdrop: View {
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0.95), location: 0),
                        .init(color: .white.opacity(0.55), location: 0.42),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(.white.opacity(0.08))
                    .frame(height: 1)
            }
    }
}

private extension View {
    func barGlass(appearance: BarAppearance) -> some View {
        let radius = CGFloat(appearance.cornerRadius)

        return background {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(.clear)
                .glassEffect(.regular, in: .rect(cornerRadius: radius))
                .opacity(appearance.opacity)
//                .shadow(color: .black.opacity(0.36), radius: 3, y: 1)
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
