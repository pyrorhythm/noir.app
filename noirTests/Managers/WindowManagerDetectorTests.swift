import Foundation
import Testing
@testable import noir

@Suite("WindowManagerDetector")
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
}