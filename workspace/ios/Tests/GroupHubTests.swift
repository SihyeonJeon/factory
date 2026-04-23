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

    func test_member_count_format_uses_korean_people_unit() {
        XCTAssertEqual(UnfadingLocalized.Groups.memberCountFormat(1), "멤버 1명")
        XCTAssertEqual(UnfadingLocalized.Groups.memberCountFormat(5), "멤버 5명")
    }

    func test_general_group_role_label_marks_owner_and_current_user() {
        XCTAssertEqual(
            GroupHubFormatting.roleLabel(mode: "general_group", isOwner: true, isCurrentUser: true),
            "그룹장 · 나"
        )
        XCTAssertEqual(
            GroupHubFormatting.roleLabel(mode: "group", isOwner: false, isCurrentUser: false),
            "멤버"
        )
        XCTAssertEqual(
            GroupHubFormatting.roleLabel(mode: "couple", isOwner: false, isCurrentUser: true),
            "파트너 · 나"
        )
    }

    func test_destructive_action_sets_warning_dialog_flag() {
        var state = GroupHubPresentationState()
        XCTAssertFalse(state.showsWarningDialog)

        state.destructiveAction = .leave
        XCTAssertTrue(state.showsWarningDialog)
        XCTAssertEqual(state.destructiveAction, .leave)

        state.destructiveAction = nil
        XCTAssertFalse(state.showsWarningDialog)
    }
}
