import SwiftUI
import XCTest
@testable import MemoryMap

final class UnfadingBottomSheetTests: XCTestCase {

    func test_snap_fractions_match_deepsight() {
        XCTAssertEqual(BottomSheetSnap.collapsed.fraction, 0.08, accuracy: 0.0001)
        XCTAssertEqual(BottomSheetSnap.default_.fraction, 0.50, accuracy: 0.0001)
        XCTAssertEqual(BottomSheetSnap.expanded.fraction, 1.0, accuracy: 0.0001)
    }

    func test_expanded_sheet_has_no_corner_radius_or_shadow() {
        XCTAssertEqual(BottomSheetSnap.expanded.topCornerRadius, 0)
        XCTAssertEqual(BottomSheetSnap.expanded.shadowRadius, 0)
        XCTAssertEqual(BottomSheetSnap.default_.topCornerRadius, UnfadingTheme.Radius.sheet)
        XCTAssertGreaterThan(BottomSheetSnap.default_.shadowRadius, 0)
    }

    func test_ordered_is_monotonic() {
        let fractions = BottomSheetSnap.ordered.map(\.fraction)
        XCTAssertEqual(fractions, fractions.sorted())
    }

    func test_available_height_uses_full_screen_plus_top_inset_when_expanded() {
        XCTAssertEqual(
            BottomSheetDragResolution.availableHeight(
                screenHeight: 800,
                tabBarHeight: 64,
                topSafeArea: 59,
                snap: .expanded
            ),
            859
        )
    }

    func test_available_height_subtracts_tab_bar_when_not_expanded() {
        XCTAssertEqual(
            BottomSheetDragResolution.availableHeight(
                screenHeight: 800,
                tabBarHeight: 64,
                topSafeArea: 59,
                snap: .default_
            ),
            736
        )
    }

    func test_collapsed_sheet_clears_tab_bar_with_8pt_padding() {
        let top = MemoryMapHomeLayout.sheetTopY(screenHeight: 800, safeBottom: 34, snap: .collapsed)
        let availableHeight: CGFloat = 800 - UnfadingTabBar.height
        let sheetHeight = availableHeight * CGFloat(BottomSheetSnap.collapsed.fraction)
        let bottomEdgeFromBottom = 800 - (top + sheetHeight)
        XCTAssertEqual(bottomEdgeFromBottom, UnfadingTabBar.height + 34 + 8, accuracy: 0.5)
    }

    func test_default_sheet_has_no_extra_clearance() {
        let top = MemoryMapHomeLayout.sheetTopY(screenHeight: 800, safeBottom: 34, snap: .default_)
        let availableHeight: CGFloat = 800 - UnfadingTabBar.height
        let sheetHeight = availableHeight * CGFloat(BottomSheetSnap.default_.fraction)
        let bottomEdgeFromBottom = 800 - (top + sheetHeight)
        XCTAssertEqual(bottomEdgeFromBottom, UnfadingTabBar.height + 34, accuracy: 0.5)
    }

    func test_tab_bar_reserve_equals_height_plus_safe_bottom() {
        XCTAssertEqual(MemoryMapHomeLayout.tabBarReserve(safeBottom: 34), UnfadingTabBar.height + 34, accuracy: 0.5)
        XCTAssertEqual(MemoryMapHomeLayout.tabBarReserve(safeBottom: 0), UnfadingTabBar.height, accuracy: 0.5)
    }

    func test_top_chrome_y_clears_dynamic_island() {
        XCTAssertEqual(MemoryMapHomeLayout.topChromeY(safeTop: 59), 67, accuracy: 0.5)
    }

    func test_filter_chip_y_below_top_chrome_with_gap() {
        XCTAssertEqual(
            MemoryMapHomeLayout.filterChipY(safeTop: 59),
            67 + MemoryMapHomeLayout.topChromeHeight + 8,
            accuracy: 0.5
        )
    }

    func test_filter_bottom_above_default_sheet_top() {
        let sheetTop = MemoryMapHomeLayout.sheetTopY(
            screenHeight: 800,
            safeBottom: 34,
            snap: .default_
        )
        let filterBottom = MemoryMapHomeLayout.filterChipY(safeTop: 59)
            + MemoryMapHomeLayout.filterChipHeight
        XCTAssertLessThan(filterBottom, sheetTop)
    }

    func test_map_controls_clear_filter_row_on_small_screens() {
        // iPhone SE 1st gen viewport (568x320 @2x = 568pt height): safeTop=20, safeBottom=0.
        // Worst-case small-screen target where filter bottom can collide with the lifted controls.
        let safeTop: CGFloat = 20
        let sheetTop = MemoryMapHomeLayout.sheetTopY(
            screenHeight: 568,
            safeBottom: 0,
            snap: .default_
        )
        let centerY = MemoryMapHomeLayout.mapControlsCenterY(safeTop: safeTop, sheetTop: sheetTop)
        let mapControlsTop = centerY - (MemoryMapHomeLayout.mapControlsStackHeight / 2)
        let mapControlsBottom = centerY + (MemoryMapHomeLayout.mapControlsStackHeight / 2)
        let filterBottom = MemoryMapHomeLayout.filterChipY(safeTop: safeTop)
            + MemoryMapHomeLayout.filterChipHeight
        XCTAssertGreaterThanOrEqual(mapControlsTop, filterBottom + MemoryMapHomeLayout.filterToMapControlsMinGap)
        XCTAssertLessThanOrEqual(mapControlsBottom, sheetTop - MemoryMapHomeLayout.filterToMapControlsMinGap + 0.5)
    }

    func test_map_controls_use_preferred_center_on_large_screens() {
        // iPhone 17 Pro: height=874, safeTop=59, safeBottom=34.
        // Plenty of vertical room → preferred center wins.
        let safeTop: CGFloat = 59
        let sheetTop = MemoryMapHomeLayout.sheetTopY(
            screenHeight: 874,
            safeBottom: 34,
            snap: .default_
        )
        let preferredCenter = sheetTop
            - MemoryMapHomeLayout.mapControlsBottomGap
            - (MemoryMapHomeLayout.mapControlsStackHeight / 2)
        let centerY = MemoryMapHomeLayout.mapControlsCenterY(safeTop: safeTop, sheetTop: sheetTop)
        XCTAssertEqual(centerY, preferredCenter, accuracy: 0.5)
    }

    func test_home_state_indicator_returns_nil_when_no_state() {
        XCTAssertNil(MemoryMapHomeLayout.homeStateIndicatorText(activeCategoryName: nil, hasSelection: false))
    }

    func test_home_state_indicator_shows_selection_only() {
        XCTAssertEqual(MemoryMapHomeLayout.homeStateIndicatorText(activeCategoryName: nil, hasSelection: true), "선택됨")
    }

    func test_home_state_indicator_shows_category_only() {
        XCTAssertEqual(MemoryMapHomeLayout.homeStateIndicatorText(activeCategoryName: "데이트", hasSelection: false), "필터: 데이트")
    }

    func test_home_state_indicator_shows_category_and_selection() {
        XCTAssertEqual(MemoryMapHomeLayout.homeStateIndicatorText(activeCategoryName: "데이트", hasSelection: true), "필터: 데이트 · 선택됨")
    }

    func test_home_action_inventory_has_at_least_seven_entries() {
        XCTAssertGreaterThanOrEqual(HomeActionInventory.all.count, 7)
    }

    func test_home_action_inventory_identifiers_non_empty() {
        for action in HomeActionInventory.all {
            XCTAssertFalse(action.identifier.isEmpty, "Empty identifier for \(action.name)")
        }
    }

    func test_home_action_inventory_meets_hit_target_minimum() {
        for action in HomeActionInventory.all {
            XCTAssertGreaterThanOrEqual(action.hitTarget, 44, "\(action.name) below 44pt")
        }
    }

    func test_home_action_inventory_covers_all_zones() {
        let zones = Set(HomeActionInventory.all.map(\.zone))
        XCTAssertTrue(zones.contains(.topNavigation))
        XCTAssertTrue(zones.contains(.mapControls))
        XCTAssertTrue(zones.contains(.composing))
        XCTAssertTrue(zones.contains(.indicator))
    }

    func test_map_controls_stack_height_uses_hit_target_not_visual_size() {
        // Layout math must reflect rendered hit-area frames (44pt), not the visual circle (40pt),
        // otherwise mapControlsCenterY clamp drifts by 4pt per button.
        XCTAssertEqual(
            MemoryMapHomeLayout.mapControlsStackHeight,
            (MemoryMapHomeLayout.mapControlsHitTargetSize * 2) + MemoryMapHomeLayout.mapControlsSpacing,
            accuracy: 0.01
        )
        XCTAssertGreaterThanOrEqual(MemoryMapHomeLayout.mapControlsHitTargetSize, 44)
    }

    func test_nearest_picks_closest_snap() {
        XCTAssertEqual(BottomSheetSnap.nearest(to: 0.10), .collapsed)
        XCTAssertEqual(BottomSheetSnap.nearest(to: 0.25), .collapsed)
        XCTAssertEqual(BottomSheetSnap.nearest(to: 0.40), .default_)
        XCTAssertEqual(BottomSheetSnap.nearest(to: 0.60), .default_)
        // midpoint(default_=0.50, expanded=1.0) = 0.75; 0.80 is comfortably nearer to expanded
        XCTAssertEqual(BottomSheetSnap.nearest(to: 0.80), .expanded)
        XCTAssertEqual(BottomSheetSnap.nearest(to: 1.20), .expanded)
    }

    func test_drag_resolution_moves_default_to_expanded_for_short_fast_upward_swipe() {
        let fullHeight: CGFloat = 800

        XCTAssertEqual(
            BottomSheetDragResolution.resolvedSnap(
                currentSnap: .default_,
                translationHeight: -20,
                velocityHeight: -600,
                fullHeight: fullHeight
            ),
            .expanded
        )
    }

    func test_drag_resolution_moves_default_to_collapsed_for_short_fast_downward_swipe() {
        let fullHeight: CGFloat = 800

        XCTAssertEqual(
            BottomSheetDragResolution.resolvedSnap(
                currentSnap: .default_,
                translationHeight: 20,
                velocityHeight: 600,
                fullHeight: fullHeight
            ),
            .collapsed
        )
    }

    func test_drag_resolution_keeps_default_for_short_low_velocity_swipe() {
        let fullHeight: CGFloat = 800

        XCTAssertEqual(
            BottomSheetDragResolution.resolvedSnap(
                currentSnap: .default_,
                translationHeight: 20,
                velocityHeight: 0,
                fullHeight: fullHeight
            ),
            .default_
        )
    }

    func test_drag_resolution_preserves_nearest_for_long_low_velocity_drag() {
        let fullHeight: CGFloat = 800

        XCTAssertEqual(
            BottomSheetDragResolution.resolvedSnap(
                currentSnap: .default_,
                translationHeight: 260,
                velocityHeight: 0,
                fullHeight: fullHeight
            ),
            .collapsed
        )
    }

    func test_drag_resolution_keeps_expanded_for_fast_upward_swipe_at_expanded() {
        let fullHeight: CGFloat = 800

        XCTAssertEqual(
            BottomSheetDragResolution.resolvedSnap(
                currentSnap: .expanded,
                translationHeight: -20,
                velocityHeight: -600,
                fullHeight: fullHeight
            ),
            .expanded
        )
    }

    func test_bottom_sheet_view_builds() {
        @State var snap: BottomSheetSnap = .default_
        let sheet = UnfadingBottomSheet(snap: .constant(snap)) {
            Text("테스트")
        }
        XCTAssertNotNil(sheet as Any)
    }
}
