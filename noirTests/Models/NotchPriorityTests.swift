import Foundation
import Testing
@testable import noir

@Suite("NotchPriority")
@MainActor
struct NotchPriorityTests {
    @Test("NotchPriority ordering")
    func priorityOrdering() {
        #expect(NotchPriority.low < NotchPriority.normal)
        #expect(NotchPriority.normal < NotchPriority.high)
        #expect(NotchPriority.high < NotchPriority.critical)
    }

    @Test("NotchPriority raw values")
    func priorityRawValues() {
        #expect(NotchPriority.low.rawValue == 0)
        #expect(NotchPriority.normal.rawValue == 1)
        #expect(NotchPriority.high.rawValue == 2)
        #expect(NotchPriority.critical.rawValue == 3)
    }
}