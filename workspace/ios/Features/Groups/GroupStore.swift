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
    @Published private(set) var members: [DBProfile] = []
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
            members = try await repo.fetchMembers(groupId: groupId)
        } catch {
            members = []
        }
    }

    @discardableResult
    func createGroup(name: String, mode: GroupMode, intro: String?) async throws -> DBGroup {
        let created = try await repo.createGroup(
            name: name,
            mode: mode == .couple ? "couple" : "group",
            intro: intro,
            coverColorHex: "#F5998C"
        )
        groups.append(created)
        activeGroupId = created.id
        await loadMembers(groupId: created.id)
        state = .loaded
        return created
    }

    @discardableResult
    func joinGroup(code: String) async throws -> DBGroup {
        let joined = try await repo.joinGroup(code: code)
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

    #if DEBUG
    static func preview(groups: [DBGroup] = [], members: [DBProfile] = []) -> GroupStore {
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
            DBProfile(
                id: group.createdBy,
                email: "uitest@example.com",
                displayName: "테스터",
                photoURL: nil,
                createdAt: Date(timeIntervalSince1970: 1_776_000_000)
            )
        ]
        state = .loaded
    }
    #endif
}

#if DEBUG
struct PreviewGroupRepository: GroupRepository {
    func fetchUserGroups() async throws -> [DBGroup] { [] }
    func fetchMembers(groupId: UUID) async throws -> [DBProfile] { [] }

    func createGroup(name: String, mode: String, intro: String?, coverColorHex: String) async throws -> DBGroup {
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

    func joinGroup(code: String) async throws -> DBGroup {
        throw CancellationError()
    }

    func rotateInviteCode(groupId: UUID) async throws -> String {
        "PREVIEW2"
    }
}
#endif
