import Foundation

struct BarLayout: Codable, Sendable, Equatable {
    var spacing: CGFloat = 8
    var horizontalPadding: CGFloat = 12

    static let `default` = BarLayout()
}
