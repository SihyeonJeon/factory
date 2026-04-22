import XCTest
@testable import MemoryMap

@MainActor
final class SettingsSanityTests: XCTestCase {

    // vibe-limit-checked: 7 Korean settings copy, 12 view smoke tests
    func test_settings_view_builds() {
        XCTAssertNotNil(SettingsView())
    }

    func test_settings_localized_strings_are_non_empty() {
        XCTAssertFalse(UnfadingLocalized.Settings.accountSection.isEmpty)
        XCTAssertFalse(UnfadingLocalized.Settings.premiumExplore.isEmpty)
        XCTAssertFalse(UnfadingLocalized.Settings.versionLabel.isEmpty)
        XCTAssertFalse(UnfadingLocalized.Theme.system.isEmpty)
    }
}
