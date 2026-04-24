import XCTest
@testable import MemoryMap

@MainActor
final class BackgroundSyncControllerTests: XCTestCase {
    func test_taskIdentifiers_matchExpectedValues() {
        XCTAssertEqual(
            BackgroundSyncController.refreshTaskIdentifier,
            "com.jeonsihyeon.memorymap.refresh"
        )
        XCTAssertEqual(
            BackgroundSyncController.rewindTaskIdentifier,
            "com.jeonsihyeon.memorymap.rewind"
        )
    }
}
