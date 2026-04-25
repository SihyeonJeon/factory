import XCTest
@testable import MemoryMap

final class UnfadingTabBarTests: XCTestCase {

    func test_tab_bar_height_is_compact_but_not_cramped() {
        XCTAssertLessThan(UnfadingTabBar.height, 80)
        XCTAssertGreaterThanOrEqual(UnfadingTabBar.height, 56)
    }

    func test_tab_button_hit_target_meets_minimum() {
        XCTAssertGreaterThanOrEqual(UnfadingTabBar.hitTargetHeight, 44)
    }
}
