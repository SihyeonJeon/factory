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

        let created = try await store.createGroup(name: "새 그룹", mode: .general, intro: "소개")

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
}
