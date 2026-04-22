import XCTest
@testable import MemoryMap

@MainActor
final class UserPreferencesTests: XCTestCase {

    // vibe-limit-checked: 5 MainActor preferences, 12 state roundtrip tests
    func test_defaults_are_loaded_when_empty() {
        let defaults = isolatedDefaults()
        let prefs = UserPreferences(userDefaults: defaults)
        XCTAssertFalse(prefs.reminderEnabled)
        XCTAssertEqual(prefs.themePreference, .system)
        XCTAssertFalse(prefs.hasSeenOnboarding)
    }

    func test_roundtrip_via_user_defaults() {
        let defaults = isolatedDefaults()
        var prefs: UserPreferences? = UserPreferences(userDefaults: defaults)
        prefs?.reminderEnabled = true
        prefs?.themePreference = .dark
        prefs?.hasSeenOnboarding = true
        prefs = nil

        let restored = UserPreferences(userDefaults: defaults)
        XCTAssertTrue(restored.reminderEnabled)
        XCTAssertEqual(restored.themePreference, .dark)
        XCTAssertTrue(restored.hasSeenOnboarding)
    }

    private func isolatedDefaults() -> UserDefaults {
        let name = "UserPreferencesTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }
}
