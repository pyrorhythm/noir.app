import SwiftUI

struct SpacerWidget: NoirWidget {
    let id = UUID()
    var displayName: String { "Spacer" }
    var systemImage: String { "arrow.left.and.right" }
    var defaultSize: WidgetSize { .small }

    var body: some View {
        Spacer()
            .frame(width: 8)
    }
}
