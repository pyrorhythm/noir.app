import Foundation

enum BarZone: String, Codable, CaseIterable, Sendable {
    case top
    case bottom
}

enum WidgetGroup: String, Codable, CaseIterable, Sendable {
    case leading
    case trailing
}
