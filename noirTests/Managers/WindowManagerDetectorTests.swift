import Foundation
import Testing
@testable import noir

@Suite("WindowManagerDetector")
@MainActor
struct WindowManagerDetectorTests {
    @Test("Initial state is disconnected")
    func initialState() {
        let detector = WindowManagerDetector()
        #expect(detector.connectionState == .disconnected)
        #expect(detector.detectedWM == nil)
    }

    @Test("Connection state enum has expected cases")
    func connectionStateCases() {
        #expect(WindowManagerDetector.ConnectionState.connected != .disconnected)
        #expect(WindowManagerDetector.ConnectionState.reconnecting != .connected)
    }

    @Test("Detect connects to a generic adapter for known running managers")
    func detectsGenericWindowManager() async {
        let detector = WindowManagerDetector { name in
            name == "yabai"
        }

        await detector.detect()

        #expect(detector.connectionState == .connected)
        #expect(detector.detectedWM?.name == "yabai")
    }

    @Test("Detect clears stale adapters when no manager is running")
    func clearsStaleAdapter() async {
        let detector = WindowManagerDetector { name in
            name == "yabai"
        }
        await detector.detect()
        #expect(detector.detectedWM?.name == "yabai")

        let disconnectedDetector = WindowManagerDetector { _ in false }
        await disconnectedDetector.detect()

        #expect(disconnectedDetector.connectionState == .disconnected)
        #expect(disconnectedDetector.detectedWM == nil)
    }
}
