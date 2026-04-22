import SwiftUI
import XCTest
@testable import MemoryMap

final class UnfadingFilterChipTests: XCTestCase {

    func test_filter_chip_builds_for_selected_and_unselected() {
        let selected = UnfadingFilterChip(title: "전체", systemImage: nil, isSelected: true, action: {})
        let unselected = UnfadingFilterChip(title: "여행", systemImage: "airplane", isSelected: false, action: {})
        XCTAssertNotNil(selected as Any)
        XCTAssertNotNil(unselected as Any)
    }

    func test_chip_title_is_required() {
        let chip = UnfadingFilterChip(title: "맛집", systemImage: "fork.knife", isSelected: false, action: {})
        XCTAssertEqual(chip.title, "맛집")
        XCTAssertEqual(chip.systemImage, "fork.knife")
    }

    func test_chip_action_callable() {
        var invoked = 0
        let chip = UnfadingFilterChip(title: "기념일", isSelected: true) { invoked += 1 }
        chip.action()
        chip.action()
        XCTAssertEqual(invoked, 2)
    }
}
