import XCTest
@testable import MemoryMap

final class ProfileSyncTests: XCTestCase {
    func test_dbProfileRoundTripsPreferences() throws {
        let json = """
        {
          "id": "33333333-3333-4333-8333-333333333333",
          "email": "profile@example.com",
          "display_name": "시현",
          "photo_url": "https://example.com/profile.png",
          "preferences": {
            "reminder_enabled": true,
            "theme_preference": "dark",
            "map_theme": "warm"
          },
          "created_at": "2026-04-23T12:00:00Z"
        }
        """.data(using: .utf8)!

        let profile = try decoder.decode(DBProfile.self, from: json)
        let encoded = try encoder.encode(profile)
        let decoded = try decoder.decode(DBProfile.self, from: encoded)

        XCTAssertEqual(decoded, profile)
        XCTAssertTrue(decoded.preferences.reminderEnabled)
        XCTAssertEqual(decoded.preferences.themePreference, "dark")
        XCTAssertEqual(decoded.preferences.mapTheme, "warm")
    }

    func test_dbProfileDefaultsEmptyPreferencesJSON() throws {
        let json = """
        {
          "id": "33333333-3333-4333-8333-333333333333",
          "email": "profile@example.com",
          "display_name": "시현",
          "photo_url": null,
          "preferences": {},
          "created_at": "2026-04-23T12:00:00Z"
        }
        """.data(using: .utf8)!

        let profile = try decoder.decode(DBProfile.self, from: json)

        XCTAssertFalse(profile.preferences.reminderEnabled)
        XCTAssertEqual(profile.preferences.themePreference, "system")
        XCTAssertEqual(profile.preferences.mapTheme, "default")
    }

    @MainActor
    func test_bootstrapFromRepositoryUpdatesPublishedValues() async {
        let userId = UUID()
        let repo = MockProfileRepository(profile: profile(
            userId: userId,
            displayName: "민지",
            photoURL: "https://example.com/minji.png",
            preferences: DBProfilePreferences(reminderEnabled: true, themePreference: "light", mapTheme: "warm")
        ))
        let prefs = UserPreferences(userDefaults: isolatedDefaults(), repository: repo)

        await prefs.bootstrap(userId: userId)

        XCTAssertTrue(prefs.reminderEnabled)
        XCTAssertEqual(prefs.themePreference, .light)
        XCTAssertEqual(prefs.mapTheme, .warm)
        XCTAssertEqual(prefs.displayName, "민지")
        XCTAssertEqual(prefs.photoURL, "https://example.com/minji.png")
    }

    @MainActor
    func test_preferenceChangeDebouncesUpdatePreferences() async {
        let userId = UUID()
        let repo = MockProfileRepository(profile: profile(userId: userId))
        let prefs = UserPreferences(userDefaults: isolatedDefaults(), repository: repo)

        await prefs.bootstrap(userId: userId)
        prefs.reminderEnabled = true
        prefs.themePreference = .dark
        prefs.mapTheme = .mono

        try? await Task.sleep(nanoseconds: 700_000_000)

        let updates = await repo.preferenceUpdates
        XCTAssertEqual(updates.count, 1)
        XCTAssertEqual(updates.first?.userId, userId)
        XCTAssertEqual(
            updates.first?.prefs,
            DBProfilePreferences(reminderEnabled: true, themePreference: "dark", mapTheme: "mono")
        )
    }

    private func profile(
        userId: UUID,
        displayName: String? = "시현",
        photoURL: String? = nil,
        preferences: DBProfilePreferences = DBProfilePreferences()
    ) -> DBProfile {
        DBProfile(
            id: userId,
            email: "profile@example.com",
            displayName: displayName,
            photoURL: photoURL,
            preferences: preferences,
            createdAt: Date(timeIntervalSince1970: 1_776_000_000)
        )
    }

    private func isolatedDefaults() -> UserDefaults {
        let name = "ProfileSyncTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}

private actor MockProfileRepository: ProfileRepository {
    private var profile: DBProfile
    private(set) var preferenceUpdates: [(prefs: DBProfilePreferences, userId: UUID)] = []
    private(set) var displayNameUpdates: [(name: String, userId: UUID)] = []
    private(set) var photoURLUpdates: [(url: String?, userId: UUID)] = []

    init(profile: DBProfile) {
        self.profile = profile
    }

    func fetchCurrent(userId: UUID) async throws -> DBProfile {
        profile
    }

    func updateDisplayName(_ name: String, userId: UUID) async throws -> DBProfile {
        displayNameUpdates.append((name, userId))
        profile = DBProfile(
            id: profile.id,
            email: profile.email,
            displayName: name,
            photoURL: profile.photoURL,
            preferences: profile.preferences,
            createdAt: profile.createdAt
        )
        return profile
    }

    func updatePhotoURL(_ url: String?, userId: UUID) async throws -> DBProfile {
        photoURLUpdates.append((url, userId))
        profile = DBProfile(
            id: profile.id,
            email: profile.email,
            displayName: profile.displayName,
            photoURL: url,
            preferences: profile.preferences,
            createdAt: profile.createdAt
        )
        return profile
    }

    func updatePreferences(_ prefs: DBProfilePreferences, userId: UUID) async throws -> DBProfile {
        preferenceUpdates.append((prefs, userId))
        profile = DBProfile(
            id: profile.id,
            email: profile.email,
            displayName: profile.displayName,
            photoURL: profile.photoURL,
            preferences: prefs,
            createdAt: profile.createdAt
        )
        return profile
    }
}
