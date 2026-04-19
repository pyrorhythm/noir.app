import Foundation

struct BarLayout: Codable, Sendable, Equatable {
    var barHeight: CGFloat = 28
    var cornerRadius: CGFloat = 0
    var spacing: CGFloat = 8
    var horizontalPadding: CGFloat = 12

    static let `default` = BarLayout()
}
