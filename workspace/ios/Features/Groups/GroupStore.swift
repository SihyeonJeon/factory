import Combine
import Foundation

@MainActor
final class GroupStore: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }

    @Published private(set) var groups: [DBGroup] = []
    @Published private(set) var activeGroupId: UUID?
    @Published private(set) var members: [DBGroupMemberWithProfile] = []
    @Published private(set) var state: LoadState = .idle

    private let repo: GroupRepository

    init(repo: GroupRepository = SupabaseGroupRepository()) {
        self.repo = repo
    }

    var activeGroup: DBGroup? {
        groups.first { $0.id == activeGroupId }
    }

    var mode: GroupMode {
        activeGroup?.mode == "couple" ? .couple : .general
    }

    var memberProfiles: [DBProfile] {
        members.map(\.profiles)
    }

    func displayName(for userId: UUID) -> String {
        guard let member = members.first(where: { $0.profiles.id == userId }) else {
            return "이름 없음"
        }

        if let nickname = member.nickname?.trimmingCharacters(in: .whitespacesAndNewlines), !nickname.isEmpty {
            return nickname
        }

        if let displayName = member.profiles.displayName?.trimmingCharacters(in: .whitespacesAndNewlines), !displayName.isEmpty {
            return displayName
        }

        return "이름 없음"
    }

    func bootstrap() async {
        state = .loading
        do {
            let list = try await repo.fetchUserGroups()
            groups = list
            if activeGroupId == nil || !list.contains(where: { $0.id == activeGroupId }) {
                activeGroupId = list.first?.id
            }
            if let id = activeGroupId {
                await loadMembers(groupId: id)
            } else {
                members = []
            }
            state = .loaded
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func setActive(_ id: UUID) {
        activeGroupId = id
        Task { await loadMembers(groupId: id) }
    }

    private func loadMembers(groupId: UUID) async {
        do {
            members = try await repo.fetchMembersWithNicknames(groupId: groupId)
        } catch {
            members = []
        }
    }

    @discardableResult
    func createGroup(name: String, mode: GroupMode, intro: String?, nickname: String?) async throws -> DBGroup {
        let created = try await repo.createGroup(
            name: name,
            mode: mode == .couple ? "couple" : "group",
            intro: intro,
            coverColorHex: "#F5998C",
            nickname: nickname
        )
        groups.append(created)
        activeGroupId = created.id
        await loadMembers(groupId: created.id)
        state = .loaded
        return created
    }

    @discardableResult
    func joinGroup(code: String, nickname: String?) async throws -> DBGroup {
        let joined = try await repo.joinGroup(code: code, nickname: nickname)
        if !groups.contains(where: { $0.id == joined.id }) {
            groups.append(joined)
        }
        activeGroupId = joined.id
        await loadMembers(groupId: joined.id)
        state = .loaded
        return joined
    }

    func rotateInvite() async throws -> String {
        guard let id = activeGroupId else {
            throw NSError(domain: "GroupStore", code: 1)
        }

        let newCode = try await repo.rotateInviteCode(groupId: id)
        if let idx = groups.firstIndex(where: { $0.id == id }) {
            groups[idx] = DBGroup(
                id: groups[idx].id,
                name: groups[idx].name,
                inviteCode: newCode,
                createdAt: groups[idx].createdAt,
                createdBy: groups[idx].createdBy,
                mode: groups[idx].mode,
                intro: groups[idx].intro,
                coverColorHex: groups[idx].coverColorHex
            )
        }
        return newCode
    }

    func updateGroupName(_ name: String) async throws {
        guard let group = activeGroup else {
            throw NSError(domain: "GroupStore", code: 1)
        }

        let updated = try await repo.updateGroupName(groupId: group.id, name: name)
        if let idx = groups.firstIndex(where: { $0.id == updated.id }) {
            groups[idx] = updated
        }
    }

    func setMyNickname(_ name: String?) async throws {
        guard let id = activeGroupId else {
            throw NSError(domain: "GroupStore", code: 1)
        }

        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let nickname = trimmed?.isEmpty == true ? nil : trimmed
        let updated = try await repo.setMyNickname(groupId: id, nickname: nickname)
        if let idx = members.firstIndex(where: { $0.id == updated.id || $0.profiles.id == updated.userId }) {
            members[idx] = DBGroupMemberWithProfile(
                id: updated.id,
                nickname: updated.nickname,
                profiles: members[idx].profiles
            )
        }
    }

    #if DEBUG
    static func preview(groups: [DBGroup] = [], members: [DBGroupMemberWithProfile] = []) -> GroupStore {
        let store = GroupStore(repo: PreviewGroupRepository())
        store.groups = groups
        store.activeGroupId = groups.first?.id
        store.members = members
        store.state = .loaded
        return store
    }

    func applyUITestStub() {
        let group = DBGroup(
            id: UUID(uuidString: "11111111-1111-4111-8111-111111111117")!,
            name: "테스트 그룹",
            inviteCode: "UITEST18",
            createdAt: Date(timeIntervalSince1970: 1_776_000_000),
            createdBy: UUID(uuidString: "00000000-0000-0000-0000-000000000017")!,
            mode: "group",
            intro: "UI 테스트 그룹",
            coverColorHex: "#F5998C"
        )
        groups = [group]
        activeGroupId = group.id
        members = [
            DBGroupMemberWithProfile(
                id: UUID(uuidString: "22222222-2222-4222-8222-222222222227")!,
                nickname: "테스터",
                profiles: DBProfile(
                    id: group.createdBy,
                    email: "uitest@example.com",
                    displayName: "UI 테스터",
                    photoURL: nil,
                    createdAt: Date(timeIntervalSince1970: 1_776_000_000)
                )
            )
        ]
        state = .loaded
    }
    #endif
}

#if DEBUG
struct PreviewGroupRepository: GroupRepository {
    func fetchUserGroups() async throws -> [DBGroup] { [] }
    func fetchMembersWithNicknames(groupId: UUID) async throws -> [DBGroupMemberWithProfile] { [] }

    func createGroup(name: String, mode: String, intro: String?, coverColorHex: String, nickname: String?) async throws -> DBGroup {
        DBGroup(
            id: UUID(),
            name: name,
            inviteCode: "PREVIEW1",
            createdAt: Date(),
            createdBy: UUID(),
            mode: mode,
            intro: intro,
            coverColorHex: coverColorHex
        )
    }

    func joinGroup(code: String, nickname: String?) async throws -> DBGroup {
        throw CancellationError()
    }

    func rotateInviteCode(groupId: UUID) async throws -> String {
        "PREVIEW2"
    }

    func updateGroupName(groupId: UUID, name: String) async throws -> DBGroup {
        DBGroup(
            id: groupId,
            name: name,
            inviteCode: "PREVIEW1",
            createdAt: Date(),
            createdBy: UUID(),
            mode: "group",
            intro: nil,
            coverColorHex: "#F5998C"
        )
    }

    func setMyNickname(groupId: UUID, nickname: String?) async throws -> DBGroupMember {
        DBGroupMember(
            id: UUID(),
            groupId: groupId,
            userId: UUID(),
            nickname: nickname,
            joinedAt: Date()
        )
    }
}
#endif
