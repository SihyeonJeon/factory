import SwiftUI
import XCTest
@testable import MemoryMap

/// Navigation contract tests for R27 `round_tabbar_shell_r1`.
final class RootNavigationTests: XCTestCase {

    func test_shell_tab_order_matches_design_handoff() {
        XCTAssertEqual(ShellTab.allCases, [.map, .calendar, .settings])
        XCTAssertEqual(ShellTab.allCases.count, 3)
    }

    func test_tab_labels_are_korean() {
        XCTAssertEqual(ShellTab.map.label, "지도")
        XCTAssertEqual(ShellTab.calendar.label, "캘린더")
        XCTAssertEqual(ShellTab.settings.label, "설정")
    }

    func test_backward_compatible_tab_strings_remain_available() {
        XCTAssertEqual(UnfadingLocalized.Tab.compose, "추억")
        XCTAssertEqual(UnfadingLocalized.Tab.rewind, "리와인드")
    }

    func test_accessibility_labels_match_tab_purpose() {
        XCTAssertTrue(ShellTab.map.accessibilityLabel.contains("지도"))
        XCTAssertTrue(ShellTab.calendar.accessibilityLabel.contains("캘린더"))
        XCTAssertTrue(ShellTab.settings.accessibilityLabel.contains("설정"))
    }

    func test_custom_tab_identifiers_are_stable() {
        XCTAssertEqual(ShellTab.map.identifier, "tab-map")
        XCTAssertEqual(ShellTab.calendar.identifier, "tab-calendar")
        XCTAssertEqual(ShellTab.settings.identifier, "tab-settings")
    }

    func test_calendar_stub_has_korean_placeholder() {
        XCTAssertFalse(UnfadingLocalized.Calendar.stubTitle.isEmpty)
        XCTAssertTrue(UnfadingLocalized.Calendar.stubTitle.contains("달력"))
        XCTAssertFalse(UnfadingLocalized.Calendar.stubBody.isEmpty)
    }

    func test_settings_stub_exposes_groups_row() {
        XCTAssertEqual(UnfadingLocalized.Settings.groupsRow, "그룹 관리")
        XCTAssertFalse(UnfadingLocalized.Settings.stubTitle.isEmpty)
        XCTAssertFalse(UnfadingLocalized.Settings.groupsRowHint.isEmpty)
    }

    func test_rewind_hint_copy_is_available() {
        XCTAssertFalse(UnfadingLocalized.Home.rewindHintTitle.isEmpty)
        XCTAssertFalse(UnfadingLocalized.Home.rewindHintBody.isEmpty)
        XCTAssertFalse(UnfadingLocalized.Home.rewindHintCta.isEmpty)
    }
}
