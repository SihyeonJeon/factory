import SwiftUI
import XCTest
@testable import MemoryMap

final class HomeSheetContentTests: XCTestCase {

    func test_archive_sort_orders_are_date_based() {
        let events = [
            SheetMemoryEvent(id: UUID(), title: "상수 루프톱 저녁", place: "상수 루프톱", date: Self.date(day: 21), photoCount: 1, photoSymbols: ["photo"], photoURLs: [], tintIndex: 0),
            SheetMemoryEvent(id: UUID(), title: "늦은 카페 회의", place: "연남 작은 카페", date: Self.date(day: 2), photoCount: 1, photoSymbols: ["photo"], photoURLs: [], tintIndex: 1)
        ]
        let latest = events.sortedEvents(order: .latest)
        let oldest = events.sortedEvents(order: .oldest)

        XCTAssertEqual(latest.first?.title, "상수 루프톱 저녁")
        XCTAssertEqual(oldest.first?.title, "늦은 카페 회의")
        XCTAssertEqual(latest.map(\.id), oldest.map(\.id).reversed())
    }

    func test_sheet_components_build_with_korean_tabs() {
        let tabs = SheetTabs(selectedTab: .constant(.curation))
        let aggregator = MemoryAggregator(memories: Self.memories())
        let eventStrip = EventStrip(events: aggregator.monthlyEvents)
        let placeRow = PlaceBundleRow(bundles: aggregator.placeBundles)
        let archiveSection = ArchiveEventSection(event: aggregator.archiveEvents[0])

        XCTAssertNotNil(tabs as Any)
        XCTAssertNotNil(eventStrip as Any)
        XCTAssertNotNil(placeRow as Any)
        XCTAssertNotNil(archiveSection as Any)
        XCTAssertEqual(SheetTab.curation.title, "큐레이션")
        XCTAssertEqual(SheetTab.archive.title, "보관함")
    }

    private static func date(day: Int) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 4, day: day))!
    }

    private static func memories() -> [DBMemory] {
        [
            memory(title: "상수 루프톱 저녁", place: "상수 루프톱", day: 21),
            memory(title: "한강 산책", place: "여의도 한강공원", day: 18)
        ]
    }

    private static func memory(title: String, place: String, day: Int) -> DBMemory {
        DBMemory(
            id: UUID(),
            userId: UUID(uuidString: "00000000-0000-0000-0000-000000000017")!,
            groupId: UUID(uuidString: "11111111-1111-4111-8111-111111111117")!,
            title: title,
            note: "노트",
            placeTitle: place,
            address: "서울",
            locationLat: 37.55,
            locationLng: 126.92,
            date: date(day: day),
            capturedAt: date(day: day),
            photoURL: nil,
            photoURLs: [],
            categories: ["food"],
            emotions: ["joy"],
            reactionCount: 0,
            createdAt: date(day: day)
        )
    }
}
