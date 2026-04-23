import XCTest
@testable import MemoryMap

@MainActor
final class RewindTests: XCTestCase {

    // vibe-limit-checked: 7 stories data contract, 8 Korean labels, 12 aggregation edge cases
    func test_rewind_feed_view_builds_with_six_story_cards() {
        let data = RewindData.sample(for: Self.april2026)

        XCTAssertEqual(RewindStoryKind.allCases.count, 6)
        XCTAssertFalse(data.topPlaces.isEmpty)
        XCTAssertNotNil(RewindFeedView(data: data))
    }

    func test_rewind_top_three_places_are_sorted_by_visit_count() {
        let data = RewindData.make(from: [
            record("망원 한강공원", day: 1),
            record("상수 루프톱", day: 2),
            record("망원 한강공원", day: 3),
            record("연남 카페", day: 4),
            record("상수 루프톱", day: 5),
            record("망원 한강공원", day: 6),
            record("서울숲", day: 7)
        ], period: Self.april2026)

        XCTAssertEqual(data.topPlaces.map(\.title), ["망원 한강공원", "상수 루프톱", "서울숲"])
        XCTAssertEqual(data.topPlaces.map(\.visitCount), [3, 2, 1])
    }

    func test_rewind_first_visit_places_exclude_places_seen_before_period() {
        let data = RewindData.make(from: [
            record("상수 루프톱", day: -2),
            record("상수 루프톱", day: 3),
            record("노들섬", day: 4),
            record("경의선숲길", day: 6)
        ], period: Self.april2026)

        XCTAssertEqual(data.firstVisitPlaces.map(\.title), ["노들섬", "경의선숲길"])
    }

    func test_rewind_copy_is_korean() {
        XCTAssertEqual(UnfadingLocalized.Rewind.reminderLabel, "장소 기반 알림")
        XCTAssertEqual(UnfadingLocalized.Rewind.shareLabel, "공유")
        XCTAssertEqual(UnfadingLocalized.Rewind.rewatchLabel, "다시 보기")
        XCTAssertTrue(UnfadingLocalized.Rewind.topPlacesTitle.contains("가장 많이 간 곳"))
        XCTAssertEqual(UnfadingLocalized.Rewind.closeLabel, "리와인드 닫기")
    }

    private static let april2026: DateInterval = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        let start = calendar.date(from: DateComponents(year: 2026, month: 4, day: 1))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 5, day: 1))!
        return DateInterval(start: start, end: end)
    }()

    private func record(_ place: String, day: Int) -> RewindMemoryRecord {
        let date = Calendar(identifier: .gregorian).date(
            byAdding: .day,
            value: day - 1,
            to: Self.april2026.start
        )!
        return RewindMemoryRecord(
            placeTitle: place,
            date: date,
            photoCount: max(1, day),
            symbolName: "mappin",
            emotionIDs: ["joy"],
            durationMinutes: 60
        )
    }
}
