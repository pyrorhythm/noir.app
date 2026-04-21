import Foundation
import Testing
@testable import noir

@Suite("BarAppearance")
@MainActor
struct BarAppearanceTests {
    @Test("Default appearance has expected values")
    func defaults() {
        let appearance = BarAppearance.default
        #expect(appearance.height == 28)
        #expect(appearance.opacity == 1)
        #expect(appearance.cornerRadius == 6)
    }

    @Test("Appearance controls describe every editable value")
    func controls() {
        #expect(BarAppearance.controls.map(\.id) == ["height", "opacity", "cornerRadius"])
    }

    @Test("BarAppearance encodes and decodes round-trip")
    func roundTrip() throws {
        let appearance = BarAppearance(height: 32, opacity: 0.8, cornerRadius: 10)
        let data = try JSONEncoder().encode(appearance)
        let decoded = try JSONDecoder().decode(BarAppearance.self, from: data)
        #expect(decoded == appearance)
    }
}
