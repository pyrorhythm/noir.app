import Foundation
import Testing
@testable import noir

@Suite("BarZone")
@MainActor
struct BarZoneTests {
    @Test("BarZone has top and bottom cases")
    func barZoneCases() {
        #expect(BarZone.allCases.count == 2)
        #expect(BarZone.allCases.contains(.top))
        #expect(BarZone.allCases.contains(.bottom))
    }

    @Test("BarZone raw values match expected strings")
    func barZoneRawValues() {
        #expect(BarZone.top.rawValue == "top")
        #expect(BarZone.bottom.rawValue == "bottom")
    }

    @Test("BarZone decodes from JSON")
    func barZoneDecode() throws {
        let json = #""top""#
        let zone = try JSONDecoder().decode(BarZone.self, from: Data(json.utf8))
        #expect(zone == .top)
    }

    @Test("WidgetGroup has leading and trailing")
    func widgetGroupCases() {
        #expect(WidgetGroup.allCases.count == 2)
        #expect(WidgetGroup.leading.rawValue == "leading")
        #expect(WidgetGroup.trailing.rawValue == "trailing")
    }
}