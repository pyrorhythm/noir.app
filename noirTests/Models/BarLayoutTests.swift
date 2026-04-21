import Foundation
import Testing
@testable import noir

@Suite("BarLayout")
@MainActor
struct BarLayoutTests {
    @Test("Default layout has expected values")
    func defaultLayout() {
        let layout = BarLayout.default
        #expect(layout.spacing == 8)
        #expect(layout.horizontalPadding == 12)
    }

    @Test("BarLayout encodes and decodes round-trip")
    func roundTrip() throws {
        let layout = BarLayout(spacing: 6, horizontalPadding: 16)
        let data = try JSONEncoder().encode(layout)
        let decoded = try JSONDecoder().decode(BarLayout.self, from: data)
        #expect(decoded.spacing == 6)
        #expect(decoded.horizontalPadding == 16)
    }
}
