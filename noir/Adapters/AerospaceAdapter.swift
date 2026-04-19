import Foundation

final class AerospaceAdapter: WindowManagerProtocol, @unchecked Sendable {
    let name: String = "aerospace"
    let socketPath: String

    init(socketPath: String = "/tmp/aerospace.sock") {
        self.socketPath = socketPath
    }

    var isRunning: Bool {
        get async {
            FileManager.default.fileExists(atPath: socketPath)
        }
    }

    func focusWorkspace(_ index: Int) async throws {
        try await sendCommand("workspace \(index)")
    }

    func moveWindow(toWorkspace index: Int) async throws {
        try await sendCommand("move window to workspace \(index)")
    }

    func activeWorkspace() async throws -> Int {
        let result = try await sendCommand("workspace --focus")
        return Int(result.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    func workspaceNames() async throws -> [String] {
        let result = try await sendCommand("workspace --list")
        return result.components(separatedBy: "\n").filter { !$0.isEmpty }
    }

    func visibleWindows() async throws -> [WindowInfo] {
        return []
    }

    var onWorkspaceChange: AsyncStream<Int>? {
        nil
    }

    private func sendCommand(_ command: String) async throws -> String {
        guard FileManager.default.fileExists(atPath: socketPath) else {
            throw AerospaceError.notRunning
        }
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/aerospace")
        process.arguments = command.components(separatedBy: " ")
        process.standardOutput = pipe
        try process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}

enum AerospaceError: LocalizedError {
    case notRunning
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .notRunning: return "aerospace is not running"
        case .commandFailed(let msg): return "aerospace command failed: \(msg)"
        }
    }
}
