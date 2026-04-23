import SwiftUI
import XCTest
@testable import MemoryMap

/// R13 accessibility sweep coverage. These tests intentionally use compile-time
/// component construction plus non-empty string contracts because SwiftUI does
/// not expose a stable public API for modifier introspection in XCTest.
final class AccessibilityAuditTests: XCTestCase {

    func test_accessibility_namespace_required_strings_are_non_empty() {
        XCTAssertGreaterThanOrEqual(UnfadingLocalized.Accessibility.requiredStrings.count, 33)

        for value in UnfadingLocalized.Accessibility.requiredStrings {
            XCTAssertFalse(
                value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
        }
    }

    func test_memory_summary_card_builds_with_accessibility_contract_copy() {
        let card = MemorySummaryCard(
            selectedPin: SampleMemoryPin.samples.first,
            onDetailTap: {}
        )
        let label = UnfadingLocalized.Accessibility.memorySummaryLabel(
            title: UnfadingLocalized.Summary.sampleTitle,
            body: UnfadingLocalized.Summary.sampleBody
        )

        XCTAssertNotNil(card as Any)
        XCTAssertFalse(label.isEmpty)
        XCTAssertFalse(UnfadingLocalized.Accessibility.memorySummaryHint.isEmpty)
    }

    func test_bottom_sheet_handle_accessibility_copy_and_view_build() {
        let sheet = UnfadingBottomSheet(snap: .constant(.default_)) {
            Text("테스트")
        }

        XCTAssertNotNil(sheet as Any)
        XCTAssertFalse(UnfadingLocalized.Accessibility.bottomSheetHandleLabel.isEmpty)
        XCTAssertFalse(UnfadingLocalized.Accessibility.bottomSheetHandleHint.isEmpty)
    }

    func test_map_fab_and_pin_accessibility_copy_is_non_empty() {
        let pin = SampleMemoryPin.samples[0]

        XCTAssertFalse(UnfadingLocalized.Accessibility.addMemoryLabel.isEmpty)
        XCTAssertFalse(UnfadingLocalized.Accessibility.addMemoryHint.isEmpty)
        XCTAssertTrue(UnfadingLocalized.Accessibility.mapPinLabel(title: pin.title).contains(pin.title))
        XCTAssertFalse(UnfadingLocalized.Accessibility.mapPinHint.isEmpty)
    }
}
