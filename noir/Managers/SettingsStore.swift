import SwiftUI

@MainActor
@Observable
final class SettingsStore {
    private let defaults: UserDefaults

    var barAppearance: BarAppearance {
        didSet {
            save(barAppearance, forKey: Keys.barAppearance)
        }
    }

    var barLayout: BarLayout {
        didSet {
            save(barLayout, forKey: Keys.barLayout)
        }
    }

    var selectedWM: String? {
        didSet {
            defaults.set(selectedWM, forKey: Keys.windowManager)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.selectedWM = defaults.string(forKey: Keys.windowManager)
        self.barAppearance = Self.loadBarAppearance(from: defaults)
        self.barLayout = Self.load(BarLayout.self, from: defaults, key: Keys.barLayout) ?? .default
    }

    private func save(_ value: some Encodable, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private static func loadBarAppearance(from defaults: UserDefaults) -> BarAppearance {
        if let data = defaults.data(forKey: Keys.barAppearance),
           let appearance = try? JSONDecoder().decode(BarAppearance.self, from: data) {
            return appearance
        }

        var migrated = BarAppearance.default
        if defaults.object(forKey: Keys.legacyBarHeight) != nil {
            let storedHeight = defaults.double(forKey: Keys.legacyBarHeight)
            migrated.height = storedHeight > 0 ? storedHeight : migrated.height
        }
        if let storedOpacity = defaults.object(forKey: Keys.legacyBarOpacity) as? Double {
            migrated.opacity = storedOpacity
        }
        if let storedCornerRadius = defaults.object(forKey: Keys.legacyBarCornerRadius) as? Double {
            migrated.cornerRadius = storedCornerRadius
        }
        return migrated
    }

    private static func load<T: Decodable>(_ type: T.Type, from defaults: UserDefaults, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private enum Keys {
        static let barAppearance = "settings.bar.appearance"
        static let barLayout = "settings.bar.layout"
        static let windowManager = "settings.windowManager"
        static let legacyBarHeight = "settings.bar.height"
        static let legacyBarCornerRadius = "settings.bar.cornerRadius"
        static let legacyBarOpacity = "settings.bar.opacity"
    }
}
