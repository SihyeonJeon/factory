import Foundation
import Supabase

protocol GroupRepository: Sendable {
    func fetchUserGroups() async throws -> [DBGroup]
    func fetchMembersWithNicknames(groupId: UUID) async throws -> [DBGroupMemberWithProfile]
    func createGroup(name: String, mode: String, intro: String?, coverColorHex: String, nickname: String?) async throws -> DBGroup
    func joinGroup(code: String, nickname: String?) async throws -> DBGroup
    func rotateInviteCode(groupId: UUID) async throws -> String
    func updateGroupName(groupId: UUID, name: String) async throws -> DBGroup
    func setMyNickname(groupId: UUID, nickname: String?) async throws -> DBGroupMember
}

struct SupabaseGroupRepository: GroupRepository {
    private var db: PostgrestClient { SupabaseService.shared.database }

    func fetchUserGroups() async throws -> [DBGroup] {
        struct Row: Decodable {
            let groups: DBGroup
        }

        let rows: [Row] = try await db.from("group_members")
            .select("groups(*)")
            .execute()
            .value
        return rows.map(\.groups)
    }

    func fetchMembersWithNicknames(groupId: UUID) async throws -> [DBGroupMemberWithProfile] {
        try await db.from("group_members")
            .select("id,nickname,profiles(*)")
            .eq("group_id", value: groupId.uuidString)
            .execute()
            .value
    }

    func createGroup(name: String, mode: String, intro: String?, coverColorHex: String, nickname: String?) async throws -> DBGroup {
        struct Params: Encodable {
            let p_name: String
            let p_mode: String
            let p_intro: String?
            let p_cover_color_hex: String
            let p_nickname: String?
        }

        return try await db.rpc(
            "create_group_with_membership",
            params: Params(
                p_name: name,
                p_mode: mode,
                p_intro: intro,
                p_cover_color_hex: coverColorHex,
                p_nickname: nickname
            )
        )
        .execute()
        .value
    }

    func joinGroup(code: String, nickname: String?) async throws -> DBGroup {
        struct Params: Encodable {
            let p_code: String
            let p_nickname: String?
        }

        return try await db.rpc("join_group_by_code", params: Params(p_code: code, p_nickname: nickname))
            .execute()
            .value
    }

    func rotateInviteCode(groupId: UUID) async throws -> String {
        struct Params: Encodable {
            let p_group_id: UUID
        }

        return try await db.rpc("rotate_invite_code", params: Params(p_group_id: groupId))
            .execute()
            .value
    }

    func updateGroupName(groupId: UUID, name: String) async throws -> DBGroup {
        struct Params: Encodable {
            let p_group_id: UUID
            let p_name: String
        }

        return try await db.rpc("update_group_name", params: Params(p_group_id: groupId, p_name: name))
            .execute()
            .value
    }

    func setMyNickname(groupId: UUID, nickname: String?) async throws -> DBGroupMember {
        struct Params: Encodable {
            let p_group_id: UUID
            let p_nickname: String?
        }

        return try await db.rpc("set_group_nickname", params: Params(p_group_id: groupId, p_nickname: nickname))
            .execute()
            .value
    }
}
