import IOKit
import Testing
@testable import noir

@Suite("MediaKeyMonitor")
struct MediaKeyMonitorTests {
    @Test("System media key codes map to notch actions")
    func mapsKnownKeyCodes() {
        #expect(MediaKeyMonitor.action(forKeyCode: NX_KEYTYPE_SOUND_UP, keyState: 0xA) == .volume(1))
        #expect(MediaKeyMonitor.action(forKeyCode: NX_KEYTYPE_SOUND_DOWN, keyState: 0xA) == .volume(-1))
        #expect(MediaKeyMonitor.action(forKeyCode: NX_KEYTYPE_MUTE, keyState: 0xA) == .volume(0))
        #expect(MediaKeyMonitor.action(forKeyCode: NX_KEYTYPE_BRIGHTNESS_UP, keyState: 0xA) == .brightness(1))
        #expect(MediaKeyMonitor.action(forKeyCode: NX_KEYTYPE_BRIGHTNESS_DOWN, keyState: 0xA) == .brightness(-1))
    }

    @Test("Key releases and unknown keys are ignored")
    func ignoresUnsupportedInput() {
        #expect(MediaKeyMonitor.action(forKeyCode: NX_KEYTYPE_SOUND_UP, keyState: 0xB) == nil)
        #expect(MediaKeyMonitor.action(forKeyCode: -1, keyState: 0xA) == nil)
    }
}
