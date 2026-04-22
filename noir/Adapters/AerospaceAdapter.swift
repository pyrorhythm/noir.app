import AppKit
import CoreGraphics
import Foundation

struct AerospaceSpace: Identifiable, Sendable, Equatable {
    let workspace: String
    var isFocused: Bool = false
    var windows: [WindowInfo] = []

    var id: String { workspace }
}

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
        try await fetchFocusedSpace()?.workspace ?? ""
    }

    func workspaceNames() async throws -> [String] {
        try await fetchSpaces().map(\.workspace)
    }

    func visibleWindows() async throws -> [WindowInfo] {
        try await fetchWindows()
    }

    func spacesWithWindows() async throws -> [AerospaceSpace] {
        async let spacesTask = fetchSpaces()
        async let windowsTask = fetchWindows()
        async let focusedSpaceTask = fetchFocusedSpace()
        async let focusedWindowTask = fetchFocusedWindow()

        var spaces = try await spacesTask
        let windows = try await windowsTask
        let focusedSpace = try? await focusedSpaceTask
        let focusedWindow = try? await focusedWindowTask

        for index in spaces.indices {
            spaces[index].isFocused = spaces[index].id == focusedSpace?.id
        }

        var spacesByID = Dictionary(uniqueKeysWithValues: spaces.map { ($0.id, $0) })
        for window in windows {
            var mutableWindow = window
            if mutableWindow.id == focusedWindow?.id {
                mutableWindow.isFocused = true
            }

            if var space = spacesByID[mutableWindow.workspace], !mutableWindow.workspace.isEmpty {
                space.windows.append(mutableWindow)
                spacesByID[space.id] = space
            } else if let focusedSpace, var space = spacesByID[focusedSpace.id] {
                mutableWindow.workspace = focusedSpace.id
                space.windows.append(mutableWindow)
                spacesByID[space.id] = space
            }
        }

        var result = Array(spacesByID.values)
        for index in result.indices {
            result[index].windows.sort { lhs, rhs in lhs.id < rhs.id }
        }
        return result
            .filter { !$0.windows.isEmpty }
            .sorted { Self.workspaceCompare($0.workspace, $1.workspace) }
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

    private func fetchSpaces() async throws -> [AerospaceSpace] {
        let output = try await sendCommand(["list-workspaces", "--all", "--json"])
        return try Self.decodeAerospaceSpaces(output)
    }

    private func fetchWindows() async throws -> [WindowInfo] {
        let output = try await sendCommand([
            "list-windows",
            "--all",
            "--json",
            "--format",
            "%{window-id} %{app-name} %{window-title} %{workspace}",
        ])
        return Self.decodeAerospaceWindows(output)
    }

    private func fetchFocusedSpace() async throws -> AerospaceSpace? {
        let output = try await sendCommand(["list-workspaces", "--focused", "--json"])
        return try Self.decodeAerospaceSpaces(output).first
    }

    private func fetchFocusedWindow() async throws -> WindowInfo? {
        let output = try await sendCommand(["list-windows", "--focused", "--json"])
        return Self.decodeAerospaceWindows(output).first
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

    static func decodeAerospaceSpaces(_ output: String) throws -> [AerospaceSpace] {
        let data = Data(output.utf8)
        let decoded = try JSONDecoder().decode([AerospaceWorkspaceDTO].self, from: data)
        return decoded.map { AerospaceSpace(workspace: $0.workspace) }
    }

    static func decodeAerospaceWindows(_ output: String, focusedWindowID: String? = nil) -> [WindowInfo] {
        guard let windows = try? JSONDecoder().decode([AerospaceWindowDTO].self, from: Data(output.utf8))
        else {
            return parseVisibleWindows(output)
        }

        return windows.map { window in
            let id = String(window.id)
            return WindowInfo(
                id: id,
                appName: window.appName ?? "",
                title: window.title,
                frame: .zero,
                workspace: window.workspace ?? "",
                isFocused: focusedWindowID == id
            )
        }
    }

    private static func workspaceCompare(_ lhs: String, _ rhs: String) -> Bool {
        switch (Int(lhs), Int(rhs)) {
        case let (lhsNumber?, rhsNumber?):
            lhsNumber < rhsNumber
        case (_?, nil):
            true
        case (nil, _?):
            false
        case (nil, nil):
            lhs < rhs
        }
    }
}

private struct AerospaceWorkspaceDTO: Decodable {
    let workspace: String
}

private struct AerospaceWindowDTO: Decodable {
    let id: Int
    let title: String
    let appName: String?
    let workspace: String?

    enum CodingKeys: String, CodingKey {
        case id = "window-id"
        case title = "window-title"
        case appName = "app-name"
        case workspace
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
