import Foundation

struct ZoneConfig: Codable, Sendable, Equatable {
    var widgets: [WidgetConfig]
}

struct LayoutConfig: Codable, Sendable, Equatable {
    var zones: [BarZone: ZoneConfig]

    static let `default` = LayoutConfig(
        zones: [
            .top: ZoneConfig(widgets: []),
            .bottom: ZoneConfig(widgets: []),
        ]
    )
}

/// Custom encoding for BarZone keys (enum as dictionary key)
extension LayoutConfig {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: BarZoneCodingKey.self)
        var zones: [BarZone: ZoneConfig] = [:]
        for key in BarZoneCodingKey.allCases {
            if let zone = BarZone(rawValue: key.rawValue),
               let config = try? container.decodeIfPresent(ZoneConfig.self, forKey: key) {
                zones[zone] = config
            }
        }
        self.zones = zones
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: BarZoneCodingKey.self)
        for (zone, config) in zones {
            guard let key = BarZoneCodingKey(rawValue: zone.rawValue) else { continue }
            try container.encode(config, forKey: key)
        }
    }
}

private enum BarZoneCodingKey: String, CodingKey, CaseIterable {
    case top
    case bottom
}

final class LayoutStore {
    private let directory: URL
    private let fileURL: URL

    init(directory: URL? = nil) {
        let dir = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("Noir")
        self.directory = dir
        self.fileURL = dir.appendingPathComponent("layout.json")
    }

    func save(_ config: LayoutConfig) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(config)
        try data.write(to: fileURL, options: .atomic)
    }

    func load() throws -> LayoutConfig {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return .default
        }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(LayoutConfig.self, from: data)
    }
}
