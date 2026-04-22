import Foundation

protocol WindowManagerProtocol: Sendable {
    var name: String { get }
    var isRunning: Bool { get async }

    func focusWorkspace(_ workspace: String) async throws
    func moveWindow(toWorkspace workspace: String) async throws

    func activeWorkspace() async throws -> String
    func workspaceNames() async throws -> [String]
    func visibleWindows() async throws -> [WindowInfo]

    var onWorkspaceChange: AsyncStream<Int>? { get }
}
