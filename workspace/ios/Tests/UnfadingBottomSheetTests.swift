import SwiftUI
import XCTest
@testable import MemoryMap

final class UnfadingBottomSheetTests: XCTestCase {

    func test_snap_fractions_match_deepsight() {
        XCTAssertEqual(BottomSheetSnap.collapsed.fraction, UnfadingTheme.Sheet.collapsed, accuracy: 0.0001)
        XCTAssertEqual(BottomSheetSnap.default_.fraction, UnfadingTheme.Sheet.default, accuracy: 0.0001)
        XCTAssertEqual(BottomSheetSnap.expanded.fraction, UnfadingTheme.Sheet.expanded, accuracy: 0.0001)
    }

    func test_ordered_is_monotonic() {
        let fractions = BottomSheetSnap.ordered.map(\.fraction)
        XCTAssertEqual(fractions, fractions.sorted())
    }

    func test_nearest_picks_closest_snap() {
        XCTAssertEqual(BottomSheetSnap.nearest(to: 0.20), .collapsed)
        XCTAssertEqual(BottomSheetSnap.nearest(to: 0.30), .collapsed)
        XCTAssertEqual(BottomSheetSnap.nearest(to: 0.40), .default_)
        XCTAssertEqual(BottomSheetSnap.nearest(to: 0.60), .default_)
        XCTAssertEqual(BottomSheetSnap.nearest(to: 0.75), .expanded)
        XCTAssertEqual(BottomSheetSnap.nearest(to: 1.20), .expanded)
    }

    func test_bottom_sheet_view_builds() {
        @State var snap: BottomSheetSnap = .default_
        let sheet = UnfadingBottomSheet(snap: .constant(snap)) {
            Text("테스트")
        }
        XCTAssertNotNil(sheet as Any)
    }
}
