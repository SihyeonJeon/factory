import XCTest
@testable import MemoryMap

final class MemoryMapHomeViewTests: XCTestCase {

    func test_layout_constants_match_prototype_sheet_chrome() {
        XCTAssertEqual(MemoryMapHomeLayout.horizontalInset, 14)
        XCTAssertEqual(MemoryMapHomeLayout.topChromeTop, 54)
        XCTAssertEqual(MemoryMapHomeLayout.filterChipTop, 108)
        XCTAssertEqual(MemoryMapHomeLayout.fabRight, 18)
        XCTAssertEqual(MemoryMapHomeLayout.fabBottomGap, 18)
        XCTAssertEqual(MemoryMapHomeLayout.mapControlsRight, 14)
        XCTAssertEqual(MemoryMapHomeLayout.mapControlsBottomGap, 88)
    }
}
