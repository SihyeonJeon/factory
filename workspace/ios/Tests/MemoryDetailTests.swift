import XCTest
@testable import MemoryMap

@MainActor
final class MemoryDetailTests: XCTestCase {

    // vibe-limit-checked: 11 sample-detail mapping, 12 behavior-adjacent view/state smoke tests
    func test_sample_memory_details_are_non_empty() {
        XCTAssertFalse(SampleMemoryDetail.samples.isEmpty)
        XCTAssertEqual(SampleMemoryDetail.samples.count, SampleMemoryPin.samples.count)
    }

    func test_memory_detail_view_builds_for_each_sample_pin() {
        for pin in SampleMemoryPin.samples {
            XCTAssertNotNil(MemoryDetailView(pin: pin))
        }
    }

    func test_pin_detail_resolution_works_for_existing_pin_ids() {
        for pin in SampleMemoryPin.samples {
            XCTAssertEqual(pin.detail()?.pinID, pin.id)
        }
    }
}
