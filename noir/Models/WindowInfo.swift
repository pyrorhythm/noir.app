import Foundation

struct WindowInfo: Identifiable, Sendable, Equatable {
    let id: String
    let appName: String
    let title: String
    let frame: CGRect
    var workspace: String
    var isFocused: Bool
}
