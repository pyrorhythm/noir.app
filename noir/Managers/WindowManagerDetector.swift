import AppKit
import Foundation

@MainActor
@Observable
final class WindowManagerDetector {
    var detectedWM: (any WindowManagerProtocol)?
    var connectionState: ConnectionState = .disconnected
    private let processChecker: @Sendable (String) -> Bool
    private let aerospace: AerospaceAdapter

    init(
        processChecker: @escaping @Sendable (String) -> Bool = WindowManagerDetector.isProcessRunning,
        aerospace: AerospaceAdapter? = nil
    ) {
        self.processChecker = processChecker
        self.aerospace = aerospace ?? AerospaceAdapter(processChecker: processChecker)
    }

    enum ConnectionState: Sendable, Equatable {
        case connected
        case disconnected
        case reconnecting
    }

    func detect() async {
        connectionState = .reconnecting

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
        NSWorkspace.shared.runningApplications.contains { app in
            app.executableURL?.deletingPathExtension().lastPathComponent == name
                || app.localizedName?.localizedCaseInsensitiveCompare(name) == .orderedSame
                || app.bundleIdentifier?.localizedCaseInsensitiveContains(name) == true
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

    func focusWorkspace(_ workspace: String) async throws {
        throw WindowManagerDetectorError.unsupportedAdapter(name)
    }

    func moveWindow(toWorkspace workspace: String) async throws {
        throw WindowManagerDetectorError.unsupportedAdapter(name)
    }

    func activeWorkspace() async throws -> String {
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
