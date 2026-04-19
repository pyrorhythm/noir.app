import Testing
import Foundation
@testable import noir

@Suite("AerospaceAdapter")
struct AerospaceAdapterTests {
    @Test("Adapter has correct name")
    func name() {
        let adapter = AerospaceAdapter()
        #expect(adapter.name == "aerospace")
    }

    @Test("isRunning returns false when aerospace not running")
    func notRunning() async {
        let adapter = AerospaceAdapter(socketPath: "/tmp/nonexistent-aerospace-socket-\(UUID().uuidString)")
        let running = await adapter.isRunning
        #expect(running == false)
    }

    @Test("onWorkspaceChange is nil by default")
    func noWorkspaceStream() {
        let adapter = AerospaceAdapter(socketPath: "/tmp/nonexistent-aerospace-socket-\(UUID().uuidString)")
        #expect(adapter.onWorkspaceChange == nil)
    }
}
