import SwiftUI

struct DynamicNotchView: View {
    @Environment(NotchManager.self) var notchManager
    @Environment(BarManager.self) var barManager

    var body: some View {
        Group {
            if let presenter = notchManager.activePresenter, notchManager.isExpanded {
                AnyNotchPresentableView(presenter: presenter)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
            } else {
                Color.clear
            }
        }
        .frame(minWidth: notchManager.isExpanded ? 120 : barManager.notchWidth)
        .animation(.spring(duration: 0.35, bounce: 0.15), value: notchManager.isExpanded)
    }
}

struct AnyNotchPresentableView: View {
    let presenter: any NotchPresentable
    
    var body: some View {
        unbox(presenter)
    }
    
    private func unbox(_ presenter: some NotchPresentable) -> AnyView {
        AnyView(presenter.notchContent)
    }
}
