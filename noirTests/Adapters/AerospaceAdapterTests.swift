import Testing
import Foundation
@testable import noir

@Suite("AerospaceAdapter")
@MainActor
struct AerospaceAdapterTests {
    @Test("Adapter has correct name")
    func name() {
        let adapter = AerospaceAdapter()
        #expect(adapter.name == "aerospace")
    }

    @Test("isRunning returns false when aerospace not running")
    func notRunning() async {
        let adapter = AerospaceAdapter(
            socketPath: "/tmp/nonexistent-aerospace-socket-\(UUID().uuidString)",
            processChecker: { _ in false }
        )
        let running = await adapter.isRunning
        #expect(running == false)
    }

    @Test("onWorkspaceChange is nil by default")
    func noWorkspaceStream() {
        let adapter = AerospaceAdapter(
            socketPath: "/tmp/nonexistent-aerospace-socket-\(UUID().uuidString)",
            processChecker: { _ in false }
        )
        #expect(adapter.onWorkspaceChange == nil)
    }

    @Test("Visible window output is parsed")
    func parsesVisibleWindows() {
        let windows = AerospaceAdapter.parseVisibleWindows("""
        42|Safari|Docs|2|true
        99|Xcode|Noir|1|false
        invalid
        """)

        #expect(windows.count == 2)
        #expect(windows[0].id == "42")
        #expect(windows[0].appName == "Safari")
        #expect(windows[0].title == "Docs")
        #expect(windows[0].workspace == "2")
        #expect(windows[0].isFocused == true)
        #expect(windows[1].isFocused == false)
    }

    @Test("AeroSpace JSON windows are decoded with workspace names")
    func decodesAerospaceJSONWindows() {
        let windows = AerospaceAdapter.decodeAerospaceWindows("""
        [
          {
            "app-name": "Codex",
            "window-id": 34276,
            "window-title": "Codex",
            "workspace": "dev"
          }
        ]
        """, focusedWindowID: "34276")

        #expect(windows.count == 1)
        #expect(windows[0].id == "34276")
        #expect(windows[0].workspace == "dev")
        #expect(windows[0].isFocused == true)
    }
}
