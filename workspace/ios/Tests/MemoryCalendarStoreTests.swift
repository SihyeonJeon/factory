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
        let memory = Self.memory(date: fixedDate)
        store.bind(memories: [memory])
        let component = Calendar.current.dateComponents([.year, .month, .day], from: fixedDate)
        XCTAssertTrue(store.hasMemory(on: component))
    }

    func test_memoryDates_recalculate_from_db_memories() {
        let store = MemoryCalendarStore(today: fixedDate)
        let first = Self.memory(id: UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1")!, date: fixedDate)
        let second = Self.memory(id: UUID(uuidString: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2")!, date: fixedDate.addingTimeInterval(86_400 * 2))

        store.bind(memories: [first, second])

        XCTAssertEqual(store.memoryDates.count, 2)
        XCTAssertTrue(store.hasMemory(on: Calendar.current.dateComponents([.year, .month, .day], from: first.date)))
        XCTAssertTrue(store.hasMemory(on: Calendar.current.dateComponents([.year, .month, .day], from: second.date)))
    }

    func test_memoriesForSelectedDate_returns_db_memories_for_selected_day() {
        let store = MemoryCalendarStore(today: fixedDate)
        let selected = fixedDate.addingTimeInterval(60 * 60 * 10)
        let sameDay = Self.memory(title: "같은 날", date: selected)
        let otherDay = Self.memory(title: "다른 날", date: fixedDate.addingTimeInterval(86_400))

        store.bind(memories: [sameDay, otherDay])
        store.select(selected)

        XCTAssertEqual(store.memoriesForSelectedDate().map(\.title), ["같은 날"])
    }

    private static func memory(
        id: UUID = UUID(),
        title: String = "상수 루프톱 저녁",
        date: Date
    ) -> DBMemory {
        DBMemory(
            id: id,
            userId: UUID(uuidString: "00000000-0000-0000-0000-000000000017")!,
            groupId: UUID(uuidString: "11111111-1111-4111-8111-111111111117")!,
            title: title,
            note: "친구들과 공연 이야기를 나눈 밤",
            placeTitle: "상수 루프톱",
            address: "서울 마포구",
            locationLat: 37.5519,
            locationLng: 126.9215,
            date: date,
            capturedAt: date,
            photoURL: nil,
            photoURLs: [],
            categories: ["food"],
            emotions: ["joy"],
            reactionCount: 0,
            createdAt: date
        )
    }
}
