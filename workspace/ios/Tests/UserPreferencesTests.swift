import XCTest
import SwiftUI
@testable import MemoryMap

@MainActor
final class UserPreferencesTests: XCTestCase {

    // vibe-limit-checked: 5 MainActor preferences, 12 state roundtrip tests
    func test_defaults_are_loaded_when_empty() {
        let defaults = isolatedDefaults()
        let prefs = UserPreferences(userDefaults: defaults)
        XCTAssertFalse(prefs.reminderEnabled)
        XCTAssertEqual(prefs.themePreference, .system)
        XCTAssertEqual(prefs.mapTheme, .default_)
        XCTAssertFalse(prefs.hasSeenOnboarding)
    }

    func test_roundtrip_via_user_defaults() {
        let defaults = isolatedDefaults()
        var prefs: UserPreferences? = UserPreferences(userDefaults: defaults)
        prefs?.reminderEnabled = true
        prefs?.themePreference = .dark
        prefs?.mapTheme = .mono
        prefs?.hasSeenOnboarding = true
        prefs = nil

        let restored = UserPreferences(userDefaults: defaults)
        XCTAssertTrue(restored.reminderEnabled)
        XCTAssertEqual(restored.themePreference, .dark)
        XCTAssertEqual(restored.mapTheme, .mono)
        XCTAssertTrue(restored.hasSeenOnboarding)
    }

    func test_theme_preference_exposes_matching_color_scheme() {
        XCTAssertNil(ThemePreference.system.colorScheme)
        XCTAssertEqual(ThemePreference.light.colorScheme, .light)
        XCTAssertEqual(ThemePreference.dark.colorScheme, .dark)
    }

    func test_bootstrap_and_preferences_sync_roundtrip_map_theme() async {
        let userId = UUID()
        let repository = MockProfileRepository(profile: profile(
            userId: userId,
            preferences: DBProfilePreferences(reminderEnabled: true, themePreference: "light", mapTheme: "warm")
        ))
        let prefs = UserPreferences(userDefaults: isolatedDefaults(), repository: repository)

        await prefs.bootstrap(userId: userId)
        XCTAssertEqual(prefs.mapTheme, .warm)

        prefs.mapTheme = .mono

        try? await Task.sleep(nanoseconds: 700_000_000)

        let updates = await repository.preferenceUpdates
        XCTAssertEqual(updates.count, 1)
        XCTAssertEqual(
            updates.first?.prefs,
            DBProfilePreferences(reminderEnabled: true, themePreference: "light", mapTheme: "mono")
        )
    }

    private func isolatedDefaults() -> UserDefaults {
        let name = "UserPreferencesTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    private func profile(
        userId: UUID,
        preferences: DBProfilePreferences = DBProfilePreferences()
    ) -> DBProfile {
        DBProfile(
            id: userId,
            email: "profile@example.com",
            displayName: "시현",
            photoURL: nil,
            preferences: preferences,
            createdAt: Date(timeIntervalSince1970: 1_776_000_000)
        )
    }
}

private actor MockProfileRepository: ProfileRepository {
    private let profile: DBProfile
    private(set) var preferenceUpdates: [(prefs: DBProfilePreferences, userId: UUID)] = []

    init(profile: DBProfile) {
        self.profile = profile
    }

    func fetchCurrent(userId: UUID) async throws -> DBProfile {
        profile
    }

    func updateDisplayName(_ name: String, userId: UUID) async throws -> DBProfile {
        profile
    }

    func updatePhotoURL(_ url: String?, userId: UUID) async throws -> DBProfile {
        profile
    }

    func updatePreferences(_ prefs: DBProfilePreferences, userId: UUID) async throws -> DBProfile {
        preferenceUpdates.append((prefs, userId))
        return DBProfile(
            id: profile.id,
            email: profile.email,
            displayName: profile.displayName,
            photoURL: profile.photoURL,
            preferences: prefs,
            createdAt: profile.createdAt
        )
    }
}
