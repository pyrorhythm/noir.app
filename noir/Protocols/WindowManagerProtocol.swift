import Foundation

protocol WindowManagerProtocol: Sendable {
    var name: String { get }
    var isRunning: Bool { get async }

    func focusWorkspace(_ index: Int) async throws
    func moveWindow(toWorkspace index: Int) async throws

    func activeWorkspace() async throws -> Int
    func workspaceNames() async throws -> [String]
    func visibleWindows() async throws -> [WindowInfo]

    var onWorkspaceChange: AsyncStream<Int>? { get }
}
