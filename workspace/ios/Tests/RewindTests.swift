import XCTest
@testable import MemoryMap

@MainActor
final class RewindTests: XCTestCase {

    // vibe-limit-checked: 7 immersive feed smoke, 8 Korean labels, 12 behavior-adjacent UI state tests
    func test_rewind_feed_view_builds_with_samples() {
        XCTAssertFalse(RewindMoment.samples.isEmpty)
        XCTAssertNotNil(RewindFeedView())
    }

    func test_rewind_reminder_row_builds_and_copy_is_korean() {
        XCTAssertNotNil(RewindReminderRow())
        XCTAssertEqual(UnfadingLocalized.Rewind.reminderLabel, "장소 기반 알림")
        XCTAssertEqual(UnfadingLocalized.Rewind.shareLabel, "공유")
        XCTAssertEqual(UnfadingLocalized.Rewind.rewatchLabel, "다시 보기")
    }
}
