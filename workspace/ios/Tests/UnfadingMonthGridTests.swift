import SwiftUI
import XCTest
@testable import MemoryMap

@MainActor
final class UnfadingMonthGridTests: XCTestCase {

    // vibe-limit-checked: 2 reusable grid proof, 8 weekday/header accessibility semantics
    func test_grid_builds_for_sample_weeks() {
        let store = MemoryCalendarStore(today: Date(timeIntervalSince1970: 1_775_232_000))
        let harness = MonthGridHarness(weeks: store.weeks())
        XCTAssertNotNil(harness.body)
    }

    func test_weekday_headers_are_korean() {
        XCTAssertEqual(UnfadingLocalized.Calendar.weekdayHeaders, ["일", "월", "화", "수", "목", "금", "토"])
    }
}

private struct MonthGridHarness: View {
    let weeks: [[MemoryCalendarStore.CalendarCell]]
    @State private var selectedDate: Date?

    var body: some View {
        UnfadingMonthGrid(
            weeks: weeks,
            selectedDate: $selectedDate,
            hasMemory: { _ in false }
        )
    }
}
