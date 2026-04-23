import Foundation
import Supabase

protocol GroupRepository: Sendable {
    func fetchUserGroups() async throws -> [DBGroup]
    func fetchMembers(groupId: UUID) async throws -> [DBProfile]
    func createGroup(name: String, mode: String, intro: String?, coverColorHex: String) async throws -> DBGroup
    func joinGroup(code: String) async throws -> DBGroup
    func rotateInviteCode(groupId: UUID) async throws -> String
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

    func fetchMembers(groupId: UUID) async throws -> [DBProfile] {
        struct Row: Decodable {
            let profiles: DBProfile
        }

        let rows: [Row] = try await db.from("group_members")
            .select("profiles(*)")
            .eq("group_id", value: groupId.uuidString)
            .execute()
            .value
        return rows.map(\.profiles)
    }

    func createGroup(name: String, mode: String, intro: String?, coverColorHex: String) async throws -> DBGroup {
        struct Params: Encodable {
            let p_name: String
            let p_mode: String
            let p_intro: String?
            let p_cover_color_hex: String
        }

        return try await db.rpc(
            "create_group_with_membership",
            params: Params(
                p_name: name,
                p_mode: mode,
                p_intro: intro,
                p_cover_color_hex: coverColorHex
            )
        )
        .execute()
        .value
    }

    func joinGroup(code: String) async throws -> DBGroup {
        struct Params: Encodable {
            let p_code: String
        }

        return try await db.rpc("join_group_by_code", params: Params(p_code: code))
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
}
