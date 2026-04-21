import Foundation
import Testing
@testable import noir

@Suite("SettingsStore")
@MainActor
struct SettingsStoreTests {
    @Test("Appearance settings persist through UserDefaults")
    func appearancePersists() {
        let suiteName = "NoirSettingsStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = SettingsStore(defaults: defaults)
        settings.barAppearance = BarAppearance(height: 34, opacity: 0.75, cornerRadius: 12)
        settings.selectedWM = "aerospace"

        let reloaded = SettingsStore(defaults: defaults)
        #expect(reloaded.barAppearance.height == 34)
        #expect(reloaded.barAppearance.opacity == 0.75)
        #expect(reloaded.barAppearance.cornerRadius == 12)
        #expect(reloaded.selectedWM == "aerospace")
    }

    @Test("Default values are used when no settings are stored")
    func defaultsWhenEmpty() {
        let suiteName = "NoirSettingsStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = SettingsStore(defaults: defaults)
        #expect(settings.barAppearance == .default)
        #expect(settings.selectedWM == nil)
    }

    @Test("Legacy appearance keys migrate into the unified appearance model")
    func legacyAppearanceMigrates() {
        let suiteName = "NoirSettingsStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(32.0, forKey: "settings.bar.height")
        defaults.set(0.8, forKey: "settings.bar.opacity")
        defaults.set(10.0, forKey: "settings.bar.cornerRadius")

        let settings = SettingsStore(defaults: defaults)
        #expect(settings.barAppearance == BarAppearance(height: 32, opacity: 0.8, cornerRadius: 10))
    }
}
