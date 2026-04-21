import Foundation
import CoreGraphics

final class AerospaceAdapter: WindowManagerProtocol, @unchecked Sendable {
    let name: String = "aerospace"
    let socketPath: String
    private let executableURL: URL

    init(
        socketPath: String = "/tmp/aerospace.sock",
        executableURL: URL? = nil
    ) {
        self.socketPath = socketPath
        self.executableURL = executableURL ?? Self.resolveExecutableURL()
    }

    var isRunning: Bool {
        get async {
            FileManager.default.fileExists(atPath: socketPath)
        }
    }

    func focusWorkspace(_ index: Int) async throws {
        _ = try await sendCommand("workspace \(index)")
    }

    func moveWindow(toWorkspace index: Int) async throws {
        _ = try await sendCommand("move window to workspace \(index)")
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
        let result = try await sendCommand(["list-windows", "--all", "--format", "%{window-id}|%{app-name}|%{window-title}|%{workspace}|%{window-is-focused}"])
        return Self.parseVisibleWindows(result)
    }

    var onWorkspaceChange: AsyncStream<Int>? {
        nil
    }

    private func sendCommand(_ command: String) async throws -> String {
        try await sendCommand(command.components(separatedBy: " "))
    }

    private func sendCommand(_ arguments: [String]) async throws -> String {
        guard FileManager.default.fileExists(atPath: socketPath) else {
            throw AerospaceError.notRunning
        }
        let process = Process()
        let stdout = Pipe()
        let stderr = Pipe()
        process.executableURL = executableURL
        process.arguments = arguments
        process.standardOutput = stdout
        process.standardError = stderr
        try process.run()
        process.waitUntilExit()
        let outputData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errorData = stderr.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8) ?? ""
        guard process.terminationStatus == 0 else {
            let message = String(data: errorData, encoding: .utf8) ?? output
            throw AerospaceError.commandFailed(message.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return output
    }

    private static func resolveExecutableURL() -> URL {
        for path in ["/opt/homebrew/bin/aerospace", "/usr/local/bin/aerospace", "/usr/bin/aerospace"] {
            if FileManager.default.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        return URL(fileURLWithPath: "/opt/homebrew/bin/aerospace")
    }

    static func parseVisibleWindows(_ output: String) -> [WindowInfo] {
        output
            .split(separator: "\n")
            .compactMap { line in
                let parts = line.split(separator: "|", omittingEmptySubsequences: false)
                guard parts.count >= 5 else { return nil }
                return WindowInfo(
                    id: String(parts[0]),
                    appName: String(parts[1]),
                    title: String(parts[2]),
                    frame: .zero,
                    workspace: Int(parts[3]) ?? 0,
                    isFocused: String(parts[4]) == "true"
                )
            }
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
