import SwiftUI

struct SystemNotchPresenter: NotchPresentable {
    enum Kind {
        case volume
        case brightness

        var title: String {
            switch self {
            case .volume: "Volume"
            case .brightness: "Brightness"
            }
        }

        var systemImage: String {
            switch self {
            case .volume: "speaker.wave.2.fill"
            case .brightness: "sun.max.fill"
            }
        }
    }

    let id = UUID()
    let kind: Kind
    let value: Double

    var displayName: String { kind.title }
    var systemImage: String { kind.systemImage }
    var defaultSize: WidgetSize { .small }
    var notchPriority: NotchPriority { .normal }
    var notchDuration: TimeInterval { 1.2 }

    var body: some View {
        EmptyView()
    }

    var notchContent: some View {
        Label(kind.title, systemImage: kind.systemImage)
            .font(.headline)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .glassEffect(.regular, in: Capsule())
    }
}
