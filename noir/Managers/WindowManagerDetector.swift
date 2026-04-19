import Foundation

@Observable
final class WindowManagerDetector {
    var detectedWM: (any WindowManagerProtocol)?
    var connectionState: ConnectionState = .disconnected

    enum ConnectionState: Sendable, Equatable {
        case connected
        case disconnected
        case reconnecting
    }

    func detect() async {
        let wmNames = ["aerospace", "yabai", "rift", "glide", "komorebi"]
        for name in wmNames {
            if isProcessRunning(name) {
                connectionState = .connected
                return
            }
        }
        connectionState = .disconnected
    }

    private func isProcessRunning(_ name: String) -> Bool {
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
