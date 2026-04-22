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
        #expect(layout.horizontalMargin == 0)
        #expect(layout.verticalOffset == 0)
    }

    @Test("BarLayout encodes and decodes round-trip")
    func roundTrip() throws {
        let layout = BarLayout(spacing: 6, horizontalPadding: 16, horizontalMargin: 40, verticalOffset: -2)
        let data = try JSONEncoder().encode(layout)
        let decoded = try JSONDecoder().decode(BarLayout.self, from: data)
        #expect(decoded.spacing == 6)
        #expect(decoded.horizontalPadding == 16)
        #expect(decoded.horizontalMargin == 40)
        #expect(decoded.verticalOffset == -2)
    }
}
