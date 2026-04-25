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
