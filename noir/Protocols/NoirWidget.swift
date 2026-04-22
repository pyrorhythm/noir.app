import SwiftUI

protocol NoirWidget: Identifiable {
    associatedtype Body: View
    var id: UUID { get }
    var displayName: String { get }
    var systemImage: String { get }
    var defaultSize: WidgetSize { get }
    var popover: AnyView? { get }
    @ViewBuilder var body: Body { get }
}

extension NoirWidget {
    var body: some View { EmptyView() }
    var popover: AnyView? { nil }
}
