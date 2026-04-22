import AppKit
import CoreGraphics
import Foundation

final class AerospaceAdapter: WindowManagerProtocol, @unchecked Sendable {
    let name: String = "aerospace"
    let socketPath: String
    private let executableURL: URL
    private let processChecker: @Sendable (String) -> Bool

    init(
        socketPath: String = "/tmp/aerospace.sock",
        executableURL: URL? = nil,
        processChecker: @escaping @Sendable (String) -> Bool = AerospaceAdapter.isProcessRunning
    ) {
        self.socketPath = socketPath
        self.executableURL = executableURL ?? Self.resolveExecutableURL()
        self.processChecker = processChecker
    }

    var isRunning: Bool {
        get async {
            FileManager.default.fileExists(atPath: socketPath) || processChecker(name)
        }
    }

    func focusWorkspace(_ workspace: String) async throws {
        _ = try await sendCommand(["workspace", workspace])
    }

    func moveWindow(toWorkspace workspace: String) async throws {
        _ = try await sendCommand(["move-node-to-workspace", workspace])
    }

    func activeWorkspace() async throws -> String {
        let result = try await sendCommand(["list-workspaces", "--focused"])
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func workspaceNames() async throws -> [String] {
        let result = try await sendCommand(["list-workspaces", "--all"])
        return result.components(separatedBy: "\n").filter { !$0.isEmpty }
    }

    func visibleWindows() async throws -> [WindowInfo] {
        async let allWindowsOutput = sendCommand([
            "list-windows",
            "--all",
            "--json",
            "--format",
            "%{window-id} %{app-name} %{window-title} %{workspace}",
        ])
        async let focusedWindowOutput = try? sendCommand(["list-windows", "--focused", "--json"])

        let focusedWindowID = await focusedWindowOutput
            .flatMap { Self.decodeAerospaceWindows($0).first?.id }
        return try await Self.decodeAerospaceWindows(allWindowsOutput, focusedWindowID: focusedWindowID)
    }

    var onWorkspaceChange: AsyncStream<Int>? {
        nil
    }

    private func sendCommand(_ command: String) async throws -> String {
        try await sendCommand(command.components(separatedBy: " "))
    }

    private func sendCommand(_ arguments: [String]) async throws -> String {
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

    nonisolated private static func isProcessRunning(_ name: String) -> Bool {
        NSWorkspace.shared.runningApplications.contains { app in
            app.executableURL?.deletingPathExtension().lastPathComponent == name
                || app.localizedName?.localizedCaseInsensitiveCompare(name) == .orderedSame
                || app.bundleIdentifier?.localizedCaseInsensitiveContains(name) == true
        }
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
                    workspace: String(parts[3]),
                    isFocused: String(parts[4]) == "true"
                )
            }
    }

    static func decodeAerospaceWindows(_ output: String, focusedWindowID: String? = nil) -> [WindowInfo] {
        guard let data = output.data(using: .utf8),
              let objects = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else {
            return parseVisibleWindows(output)
        }

        return objects.compactMap { object in
            guard let id = stringValue(object, keys: ["window-id", "window_id", "windowId"]),
                  let appName = stringValue(object, keys: ["app-name", "app_name", "appName"]),
                  let title = stringValue(object, keys: ["window-title", "window_title", "windowTitle"]),
                  let workspace = stringValue(object, keys: ["workspace"])
            else {
                return nil
            }

            let isFocused = boolValue(object, keys: ["window-is-focused", "window_is_focused", "is_focused", "isFocused"])
                ?? (focusedWindowID == id)

            return WindowInfo(
                id: id,
                appName: appName,
                title: title,
                frame: .zero,
                workspace: workspace,
                isFocused: isFocused
            )
        }
    }

    private static func stringValue(_ object: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = object[key] as? String {
                return value
            }
            if let value = object[key] as? NSNumber {
                return value.stringValue
            }
        }
        return nil
    }

    private static func boolValue(_ object: [String: Any], keys: [String]) -> Bool? {
        for key in keys {
            if let value = object[key] as? Bool {
                return value
            }
            if let value = object[key] as? NSNumber {
                return value.boolValue
            }
            if let value = object[key] as? String {
                return value == "true" || value == "1"
            }
        }
        return nil
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
