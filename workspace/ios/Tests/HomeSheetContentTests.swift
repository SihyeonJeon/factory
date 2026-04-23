import SwiftUI
import XCTest
@testable import MemoryMap

final class HomeSheetContentTests: XCTestCase {

    func test_archive_sample_totals_match_header_contract() {
        XCTAssertEqual(SampleSheetData.archiveEvents.count, 4)
        XCTAssertEqual(SampleSheetData.totalArchivePhotoCount, 18)
    }

    func test_archive_sort_orders_are_date_based() {
        let latest = SampleSheetData.archiveEvents.sortedEvents(order: .latest)
        let oldest = SampleSheetData.archiveEvents.sortedEvents(order: .oldest)

        XCTAssertEqual(latest.first?.title, "상수 루프톱 저녁")
        XCTAssertEqual(oldest.first?.title, "늦은 카페 회의")
        XCTAssertEqual(latest.map(\.id), oldest.map(\.id).reversed())
    }

    func test_place_bundles_only_include_three_plus_visits() {
        XCTAssertFalse(SampleSheetData.placeBundles.isEmpty)
        XCTAssertTrue(SampleSheetData.placeBundles.allSatisfy { $0.visitCount >= 3 })
    }

    func test_sheet_components_build_with_korean_tabs() {
        let tabs = SheetTabs(selectedTab: .constant(.curation))
        let eventStrip = EventStrip(events: SampleSheetData.monthlyEvents)
        let placeRow = PlaceBundleRow(bundles: SampleSheetData.placeBundles)
        let archiveSection = ArchiveEventSection(event: SampleSheetData.archiveEvents[0])

        XCTAssertNotNil(tabs as Any)
        XCTAssertNotNil(eventStrip as Any)
        XCTAssertNotNil(placeRow as Any)
        XCTAssertNotNil(archiveSection as Any)
        XCTAssertEqual(SheetTab.curation.title, "큐레이션")
        XCTAssertEqual(SheetTab.archive.title, "보관함")
    }
}
