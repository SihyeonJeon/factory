import XCTest
@testable import MemoryMap

@MainActor
final class GroupHubTests: XCTestCase {

    // vibe-limit-checked: 11 sample group data, 12 mode transition tests, 14 reusable avatar overflow
    func test_sample_groups_have_members() {
        XCTAssertFalse(SampleGroup.sampleCouple.members.isEmpty)
        XCTAssertFalse(SampleGroup.sampleGeneral.members.isEmpty)
    }

    func test_sample_group_member_accepts_database_id() {
        let id = UUID()
        let member = SampleGroupMember(id: id, name: "시현", initial: "시", relation: "")

        XCTAssertEqual(member.id, id)
        XCTAssertEqual(member.initial, "시")
    }

    func test_avatar_stack_overflow_count() {
        XCTAssertEqual(UnfadingAvatarStack.overflowCount(total: 5, maxDisplay: 4), 1)
        XCTAssertEqual(UnfadingAvatarStack.overflowCount(total: 3, maxDisplay: 4), 0)
    }
}
