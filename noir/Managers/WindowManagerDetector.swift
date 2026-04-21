import Foundation

@MainActor
@Observable
final class WindowManagerDetector {
    var detectedWM: (any WindowManagerProtocol)?
    var connectionState: ConnectionState = .disconnected
    private let processChecker: (String) -> Bool

    init(processChecker: @escaping (String) -> Bool = WindowManagerDetector.isProcessRunning) {
        self.processChecker = processChecker
    }

    enum ConnectionState: Sendable, Equatable {
        case connected
        case disconnected
        case reconnecting
    }

    func detect() async {
        connectionState = .reconnecting

        let aerospace = AerospaceAdapter()
        let aerospaceIsRunning = await aerospace.isRunning
        if processChecker(aerospace.name) || aerospaceIsRunning {
            detectedWM = aerospace
            connectionState = .connected
            return
        }

        for name in ["yabai", "rift", "glide", "komorebi"] where processChecker(name) {
            detectedWM = DetectedWindowManagerAdapter(name: name)
            connectionState = .connected
            return
        }

        detectedWM = nil
        connectionState = .disconnected
    }

    nonisolated private static func isProcessRunning(_ name: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        process.arguments = ["-x", name]
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}

private final class DetectedWindowManagerAdapter: WindowManagerProtocol, @unchecked Sendable {
    let name: String

    init(name: String) {
        self.name = name
    }

    var isRunning: Bool {
        get async { true }
    }

    func focusWorkspace(_ index: Int) async throws {
        throw WindowManagerDetectorError.unsupportedAdapter(name)
    }

    func moveWindow(toWorkspace index: Int) async throws {
        throw WindowManagerDetectorError.unsupportedAdapter(name)
    }

    func activeWorkspace() async throws -> Int {
        throw WindowManagerDetectorError.unsupportedAdapter(name)
    }

    func workspaceNames() async throws -> [String] {
        []
    }

    func visibleWindows() async throws -> [WindowInfo] {
        []
    }

    var onWorkspaceChange: AsyncStream<Int>? {
        nil
    }
}

enum WindowManagerDetectorError: LocalizedError {
    case unsupportedAdapter(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedAdapter(let name):
            "\(name) was detected, but Noir does not have a command adapter for it yet."
        }
    }
}
