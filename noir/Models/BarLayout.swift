import Foundation

struct BarLayout: Codable, Sendable, Equatable {
    var spacing: CGFloat = 8
    var horizontalPadding: CGFloat = 12
    var horizontalMargin: CGFloat = 0
    var verticalOffset: CGFloat = 0

    init(
        spacing: CGFloat = 8,
        horizontalPadding: CGFloat = 12,
        horizontalMargin: CGFloat = 0,
        verticalOffset: CGFloat = 0
    ) {
        self.spacing = spacing
        self.horizontalPadding = horizontalPadding
        self.horizontalMargin = horizontalMargin
        self.verticalOffset = verticalOffset
    }

    static let `default` = BarLayout()
}
