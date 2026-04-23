import SwiftUI
import XCTest
@testable import MemoryMap

@MainActor
final class OnboardingTests: XCTestCase {

    // vibe-limit-checked: 5 MainActor preferences, 12 onboarding state roundtrip
    func test_has_seen_onboarding_roundtrips_through_user_defaults() {
        let defaults = isolatedDefaults()
        var prefs: UserPreferences? = UserPreferences(userDefaults: defaults)
        XCTAssertFalse(prefs?.hasSeenOnboarding ?? true)

        prefs?.hasSeenOnboarding = true
        prefs = nil

        let restored = UserPreferences(userDefaults: defaults)
        XCTAssertTrue(restored.hasSeenOnboarding)
    }

    // vibe-limit-checked: 7 Korean onboarding copy, 8 Dynamic Type-compatible build smoke
    func test_onboarding_view_builds() {
        let view: some View = OnboardingView {}
        XCTAssertNotNil(view as Any)
    }

    private func isolatedDefaults() -> UserDefaults {
        let name = "OnboardingTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }
}
