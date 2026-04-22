import XCTest
@testable import MemoryMap

@MainActor
final class MemoryCalendarStoreTests: XCTestCase {

    // vibe-limit-checked: 5 MainActor calendar state, 7 deterministic month math, 12 behavioral tests
    private let fixedDate = Date(timeIntervalSince1970: 1_775_232_000) // 2026-04-01 00:00:00 UTC

    func test_init_produces_start_of_current_month() {
        let store = MemoryCalendarStore(today: fixedDate)
        let components = Calendar.current.dateComponents([.day], from: store.displayedMonth)
        XCTAssertEqual(components.day, 1)
    }

    func test_next_and_previous_month_change_displayed_month() {
        let store = MemoryCalendarStore(today: fixedDate)
        let originalTitle = store.monthTitle()
        store.nextMonth()
        XCTAssertNotEqual(store.monthTitle(), originalTitle)
        store.previousMonth()
        XCTAssertEqual(store.monthTitle(), originalTitle)
    }

    func test_select_and_unselect() {
        let store = MemoryCalendarStore(today: fixedDate)
        store.select(fixedDate)
        XCTAssertNotNil(store.selectedDate)
        store.select(nil)
        XCTAssertNil(store.selectedDate)
    }

    func test_weeks_returns_six_weeks_of_seven_days() {
        let store = MemoryCalendarStore(today: fixedDate)
        let weeks = store.weeks()
        XCTAssertEqual(weeks.count, 6)
        XCTAssertTrue(weeks.allSatisfy { $0.count == 7 })
    }

    func test_has_memory_works_for_seeded_components() {
        let store = MemoryCalendarStore(today: fixedDate)
        guard let component = store.memoryDates.first else {
            XCTFail("memoryDates should be seeded")
            return
        }
        XCTAssertTrue(store.hasMemory(on: component))
    }
}
