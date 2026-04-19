import Foundation
import Testing
@testable import noir

@Suite("BarLayout")
struct BarLayoutTests {
    @Test("Default layout has expected values")
    func defaultLayout() {
        let layout = BarLayout.default
        #expect(layout.barHeight == 28)
        #expect(layout.cornerRadius == 0)
        #expect(layout.spacing == 8)
        #expect(layout.horizontalPadding == 12)
    }

    @Test("BarLayout encodes and decodes round-trip")
    func roundTrip() throws {
        let layout = BarLayout(barHeight: 32, cornerRadius: 10, spacing: 6, horizontalPadding: 16)
        let data = try JSONEncoder().encode(layout)
        let decoded = try JSONDecoder().decode(BarLayout.self, from: data)
        #expect(decoded.barHeight == 32)
        #expect(decoded.cornerRadius == 10)
        #expect(decoded.spacing == 6)
        #expect(decoded.horizontalPadding == 16)
    }
}