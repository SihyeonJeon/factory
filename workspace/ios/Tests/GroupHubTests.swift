import XCTest
@testable import MemoryMap

@MainActor
final class GroupHubTests: XCTestCase {

    // vibe-limit-checked: 11 sample group data, 12 mode transition tests, 14 reusable avatar overflow
    func test_sample_groups_have_members() {
        XCTAssertFalse(SampleGroup.sampleCouple.members.isEmpty)
        XCTAssertFalse(SampleGroup.sampleGeneral.members.isEmpty)
    }

    func test_group_store_switches_current_group_by_mode() {
        let store = GroupStore()
        XCTAssertEqual(store.currentGroup.mode, .couple)
        store.setMode(.general)
        XCTAssertEqual(store.mode, .general)
        XCTAssertEqual(store.currentGroup.mode, .general)
        store.setMode(.couple)
        XCTAssertEqual(store.currentGroup.mode, .couple)
    }

    func test_avatar_stack_overflow_count() {
        XCTAssertEqual(UnfadingAvatarStack.overflowCount(total: 5, maxDisplay: 4), 1)
        XCTAssertEqual(UnfadingAvatarStack.overflowCount(total: 3, maxDisplay: 4), 0)
    }
}
