import SwiftUI
import XCTest
@testable import MemoryMap

final class UnfadingBottomSheetTests: XCTestCase {

    func test_snap_fractions_match_deepsight() {
        XCTAssertEqual(BottomSheetSnap.collapsed.fraction, 0.085, accuracy: 0.0001)
        XCTAssertEqual(BottomSheetSnap.default_.fraction, 0.52, accuracy: 0.0001)
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

    func test_nearest_picks_closest_snap() {
        XCTAssertEqual(BottomSheetSnap.nearest(to: 0.10), .collapsed)
        XCTAssertEqual(BottomSheetSnap.nearest(to: 0.25), .collapsed)
        XCTAssertEqual(BottomSheetSnap.nearest(to: 0.40), .default_)
        XCTAssertEqual(BottomSheetSnap.nearest(to: 0.60), .default_)
        // midpoint(default_=0.52, expanded=1.0) = 0.76; 0.80 is comfortably nearer to expanded
        XCTAssertEqual(BottomSheetSnap.nearest(to: 0.80), .expanded)
        XCTAssertEqual(BottomSheetSnap.nearest(to: 1.20), .expanded)
    }

    func test_drag_resolution_uses_nearest_projected_snap_with_velocity() {
        let fullHeight: CGFloat = 800

        XCTAssertEqual(
            BottomSheetDragResolution.resolvedSnap(
                currentSnap: .default_,
                translationHeight: -220,
                velocityHeight: -600,
                fullHeight: fullHeight
            ),
            .expanded
        )

        XCTAssertEqual(
            BottomSheetDragResolution.resolvedSnap(
                currentSnap: .default_,
                translationHeight: 260,
                velocityHeight: 200,
                fullHeight: fullHeight
            ),
            .collapsed
        )

        XCTAssertEqual(
            BottomSheetDragResolution.resolvedSnap(
                currentSnap: .expanded,
                translationHeight: 300,
                velocityHeight: 0,
                fullHeight: fullHeight
            ),
            .default_
        )

        XCTAssertEqual(
            BottomSheetDragResolution.resolvedSnap(
                currentSnap: .collapsed,
                translationHeight: -700,
                velocityHeight: -3_000,
                fullHeight: fullHeight
            ),
            .default_
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
