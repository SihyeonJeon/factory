import XCTest
@testable import MemoryMap

@MainActor
final class GroupStoreTests: XCTestCase {
    func test_previewInitWithGroupsSelectsFirstAndDerivesMode() {
        let first = makeGroup(name: "우리", mode: "couple")
        let second = makeGroup(name: "친구", mode: "group")

        let store = GroupStore.preview(groups: [first, second])

        XCTAssertEqual(store.activeGroupId, first.id)
        XCTAssertEqual(store.activeGroup, first)
        XCTAssertEqual(store.mode, .couple)
    }

    func test_createGroupUpdatesGroupsAndActiveGroupId() async throws {
        let store = GroupStore(repo: PreviewGroupRepository())

        let created = try await store.createGroup(name: "새 그룹", mode: .general, intro: "소개", nickname: "나")

        XCTAssertEqual(store.groups, [created])
        XCTAssertEqual(store.activeGroupId, created.id)
        XCTAssertEqual(store.mode, .general)
        XCTAssertEqual(created.name, "새 그룹")
        XCTAssertEqual(created.mode, "group")
    }

    func test_rotateInviteUpdatesInviteCode() async throws {
        let group = makeGroup(name: "초대", mode: "group", inviteCode: "OLD12345")
        let store = GroupStore.preview(groups: [group])

        let newCode = try await store.rotateInvite()

        XCTAssertEqual(newCode, "PREVIEW2")
        XCTAssertEqual(store.activeGroup?.inviteCode, "PREVIEW2")
    }

    func test_updateGroupNameUpdatesLocalGroupsArray() async throws {
        let group = makeGroup(name: "이전 이름", mode: "group")
        let store = GroupStore(repo: StaticGroupRepository(group: group))
        await store.bootstrap()

        try await store.updateGroupName("새 이름")

        XCTAssertEqual(store.activeGroup?.name, "새 이름")
    }

    func test_setMyNicknameUpdatesMatchingMemberRow() async throws {
        let userId = UUID()
        let memberId = UUID()
        let group = makeGroup(name: "닉네임", mode: "group")
        let member = makeMember(id: memberId, userId: userId, nickname: nil, displayName: "프로필 이름")
        let store = GroupStore(repo: StaticGroupRepository(group: group, members: [member], nicknameUserId: userId))
        await store.bootstrap()

        try await store.setMyNickname("그룹 이름")

        XCTAssertEqual(store.members.first?.id, memberId)
        XCTAssertEqual(store.members.first?.nickname, "그룹 이름")
    }

    func test_displayNamePrefersNicknameOverProfileDisplayName() async {
        let userId = UUID()
        let group = makeGroup(name: "표시 이름", mode: "group")
        let member = makeMember(id: UUID(), userId: userId, nickname: "그룹 별명", displayName: "프로필 이름")
        let store = GroupStore(repo: StaticGroupRepository(group: group, members: [member], nicknameUserId: userId))
        await store.bootstrap()

        XCTAssertEqual(store.displayName(for: userId), "그룹 별명")
        XCTAssertEqual(store.memberProfiles.map(\.id), [userId])
    }

    private func makeGroup(name: String, mode: String, inviteCode: String = "ABCDEFGH") -> DBGroup {
        DBGroup(
            id: UUID(),
            name: name,
            inviteCode: inviteCode,
            createdAt: Date(timeIntervalSince1970: 1_776_000_000),
            createdBy: UUID(),
            mode: mode,
            intro: nil,
            coverColorHex: "#F5998C"
        )
    }

    private func makeMember(
        id: UUID,
        userId: UUID,
        nickname: String?,
        displayName: String?
    ) -> DBGroupMemberWithProfile {
        DBGroupMemberWithProfile(
            id: id,
            nickname: nickname,
            profiles: DBProfile(
                id: userId,
                email: nil,
                displayName: displayName,
                photoURL: nil,
                createdAt: nil
            )
        )
    }
}

private struct StaticGroupRepository: GroupRepository {
    let group: DBGroup
    var members: [DBGroupMemberWithProfile] = []
    var nicknameUserId: UUID = UUID()

    func fetchUserGroups() async throws -> [DBGroup] {
        [group]
    }

    func fetchMembersWithNicknames(groupId: UUID) async throws -> [DBGroupMemberWithProfile] {
        members
    }

    func createGroup(name: String, mode: String, intro: String?, coverColorHex: String, nickname: String?) async throws -> DBGroup {
        group
    }

    func joinGroup(code: String, nickname: String?) async throws -> DBGroup {
        group
    }

    func rotateInviteCode(groupId: UUID) async throws -> String {
        "ROTATED1"
    }

    func updateGroupName(groupId: UUID, name: String) async throws -> DBGroup {
        DBGroup(
            id: group.id,
            name: name,
            inviteCode: group.inviteCode,
            createdAt: group.createdAt,
            createdBy: group.createdBy,
            mode: group.mode,
            intro: group.intro,
            coverColorHex: group.coverColorHex
        )
    }

    func setMyNickname(groupId: UUID, nickname: String?) async throws -> DBGroupMember {
        DBGroupMember(
            id: members.first?.id ?? UUID(),
            groupId: groupId,
            userId: nicknameUserId,
            nickname: nickname,
            joinedAt: nil
        )
    }
}
