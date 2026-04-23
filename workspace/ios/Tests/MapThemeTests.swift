import XCTest
@testable import MemoryMap

final class MapThemeTests: XCTestCase {
    func test_rawValueMapping_roundTripsAllThemes() {
        XCTAssertEqual(MapTheme.default_.rawValue, "default")
        XCTAssertEqual(MapTheme.warm.rawValue, "warm")
        XCTAssertEqual(MapTheme.mono.rawValue, "mono")

        XCTAssertEqual(MapTheme(rawValue: "default"), .default_)
        XCTAssertEqual(MapTheme(rawValue: "warm"), .warm)
        XCTAssertEqual(MapTheme(rawValue: "mono"), .mono)
    }

    func test_allCases_order_matches_groupHubSelectionRows() {
        XCTAssertEqual(MapTheme.allCases, [.default_, .warm, .mono])
    }
}
