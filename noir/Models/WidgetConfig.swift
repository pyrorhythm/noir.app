import Foundation

enum WidgetConfigValue: Codable, Sendable, Equatable {
    case string(String)
    case double(Double)
    case bool(Bool)

    var stringValue: String? {
        if case .string(let v) = self { return v }
        return nil
    }

    var doubleValue: Double? {
        if case .double(let v) = self { return v }
        return nil
    }

    var boolValue: Bool? {
        if case .bool(let v) = self { return v }
        return nil
    }
}

struct WidgetConfig: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    var type: String
    var size: WidgetSize
    var zone: BarZone
    var group: WidgetGroup
    var index: Int
    var settings: [String: WidgetConfigValue]

    init(id: UUID, type: String, size: WidgetSize, zone: BarZone, group: WidgetGroup, index: Int, settings: [String: WidgetConfigValue]) {
        self.id = id
        self.type = type
        self.size = size
        self.zone = zone
        self.group = group
        self.index = index
        self.settings = settings
    }
}
