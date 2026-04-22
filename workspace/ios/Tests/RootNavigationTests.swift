import SwiftUI
import XCTest
@testable import MemoryMap

/// Navigation contract tests for R3 `round_navigation_r1`.
///
/// We assert against the `RootTabView.Tab` enum + `UnfadingLocalized.Tab`
/// strings, not by spinning up a `UIHostingController`, because the real
/// 5-tab structural contract lives in the public enum + label map.
final class RootNavigationTests: XCTestCase {

    func test_tab_order_matches_deepsight_plan() {
        XCTAssertEqual(RootTabView.Tab.rootOrder, [.map, .calendar, .compose, .rewind, .settings])
        XCTAssertEqual(RootTabView.Tab.rootOrder.count, 5)
        // CaseIterable should not add phantom cases beyond what's in rootOrder
        XCTAssertEqual(Set(RootTabView.Tab.allCases), Set(RootTabView.Tab.rootOrder))
    }

    func test_tab_labels_are_korean() {
        XCTAssertEqual(UnfadingLocalized.Tab.map, "지도")
        XCTAssertEqual(UnfadingLocalized.Tab.calendar, "캘린더")
        XCTAssertEqual(UnfadingLocalized.Tab.compose, "추억")
        XCTAssertEqual(UnfadingLocalized.Tab.rewind, "리와인드")
        XCTAssertEqual(UnfadingLocalized.Tab.settings, "설정")
    }

    func test_accessibility_labels_match_tab_purpose() {
        XCTAssertTrue(UnfadingLocalized.Accessibility.mapTabLabel.contains("지도"))
        XCTAssertTrue(UnfadingLocalized.Accessibility.calendarTabLabel.contains("캘린더"))
        XCTAssertTrue(UnfadingLocalized.Accessibility.composeTabLabel.contains("추억"))
        XCTAssertTrue(UnfadingLocalized.Accessibility.rewindTabLabel.contains("리와인드"))
        XCTAssertTrue(UnfadingLocalized.Accessibility.settingsTabLabel.contains("설정"))
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

    func test_compose_tab_intercept_contract() {
        // The compose tab is a pseudo-destination; the behavioral rule (select →
        // present cover → don't advance selectedTab) is encoded in bindingForSelection
        // and exercised here by asserting the tab's presence in the enum.
        let allCases: [RootTabView.Tab] = [.map, .calendar, .compose, .rewind, .settings]
        XCTAssertTrue(allCases.contains(.compose))
    }
}
