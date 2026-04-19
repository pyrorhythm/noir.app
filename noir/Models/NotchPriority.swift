import Foundation

enum NotchPriority: Int, Comparable, Codable, Sendable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3

    static func < (lhs: NotchPriority, rhs: NotchPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
