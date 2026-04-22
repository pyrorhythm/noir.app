import Foundation

struct WindowInfo: Identifiable, Sendable, Equatable {
    let id: String
    let appName: String
    let title: String
    let frame: CGRect
    let workspace: String
    let isFocused: Bool
}
