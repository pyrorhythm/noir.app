import Foundation
import Testing
@testable import noir

@Suite("WidgetConfig")
@MainActor
struct WidgetConfigTests {
    @Test("WidgetSize has small, medium, large")
    func widgetSizeCases() {
        #expect(WidgetSize.allCases.count == 3)
        #expect(WidgetSize.small.rawValue == "small")
        #expect(WidgetSize.medium.rawValue == "medium")
        #expect(WidgetSize.large.rawValue == "large")
    }

    @Test("WidgetConfig encodes and decodes round-trip")
    func roundTrip() throws {
        let config = WidgetConfig(
            id: UUID(),
            type: "Clock",
            size: .medium,
            zone: .top,
            group: .leading,
            index: 0,
            settings: ["format": .string("HH:mm")]
        )
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(WidgetConfig.self, from: data)
        #expect(decoded.type == "Clock")
        #expect(decoded.size == .medium)
        #expect(decoded.zone == .top)
        #expect(decoded.group == .leading)
        #expect(decoded.index == 0)
    }
}
