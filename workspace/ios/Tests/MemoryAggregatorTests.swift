import XCTest
@testable import MemoryMap

final class MemoryAggregatorTests: XCTestCase {
    func test_recentEvents_sort_by_newest_and_preserve_photo_urls() {
        let older = Self.memory(title: "오래된 추억", day: 3, photoURLs: ["old.jpg"])
        let newer = Self.memory(title: "새 추억", day: 21, photoURLs: ["new-1.jpg", "new-2.jpg"])

        let aggregator = MemoryAggregator(memories: [older, newer], now: Self.date(day: 24))

        XCTAssertEqual(aggregator.recentEvents.map(\.title), ["새 추억", "오래된 추억"])
        XCTAssertEqual(aggregator.recentEvents.first?.photoURLs, ["new-1.jpg", "new-2.jpg"])
        XCTAssertEqual(aggregator.recentEvents.first?.photoCount, 2)
    }

    func test_placeBundles_group_by_place_and_count_visits() {
        let sangsu1 = Self.memory(title: "저녁", place: "상수 루프톱", day: 21, photoURLs: ["a.jpg"])
        let sangsu2 = Self.memory(title: "디저트", place: "상수 루프톱", day: 22, photoURLs: ["b.jpg"])
        let hangang = Self.memory(title: "산책", place: "여의도 한강공원", day: 18, photoURLs: [])

        let aggregator = MemoryAggregator(memories: [hangang, sangsu1, sangsu2], now: Self.date(day: 24))

        XCTAssertEqual(aggregator.placeBundles.first?.place, "상수 루프톱")
        XCTAssertEqual(aggregator.placeBundles.first?.visitCount, 2)
        XCTAssertEqual(aggregator.placeBundles.first?.photoURLs, ["b.jpg", "a.jpg"])
    }

    func test_monthlyEvents_falls_back_to_recent_when_current_month_empty() {
        let memory = Self.memory(title: "지난달", day: 1)
        let aggregator = MemoryAggregator(memories: [memory], now: Self.date(month: 5, day: 24))

        XCTAssertEqual(aggregator.monthlyEvents.map(\.title), ["지난달"])
    }

    private static func date(month: Int = 4, day: Int) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: month, day: day))!
    }

    private static func memory(
        title: String,
        place: String = "상수 루프톱",
        day: Int,
        photoURLs: [String] = []
    ) -> DBMemory {
        DBMemory(
            id: UUID(),
            userId: UUID(uuidString: "00000000-0000-0000-0000-000000000017")!,
            groupId: UUID(uuidString: "11111111-1111-4111-8111-111111111117")!,
            title: title,
            note: "노트",
            placeTitle: place,
            address: "서울",
            locationLat: 37.5519,
            locationLng: 126.9215,
            date: date(day: day),
            capturedAt: date(day: day),
            photoURL: nil,
            photoURLs: photoURLs,
            categories: ["food"],
            emotions: ["joy"],
            reactionCount: 1,
            createdAt: date(day: day)
        )
    }
}
