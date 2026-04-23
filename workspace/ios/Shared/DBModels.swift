import Foundation

struct DBProfile: Codable, Hashable, Identifiable {
    let id: UUID
    let email: String?
    let displayName: String?
    let photoURL: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, email
        case displayName = "display_name"
        case photoURL = "photo_url"
        case createdAt = "created_at"
    }
}

struct DBGroup: Codable, Hashable, Identifiable {
    let id: UUID
    let name: String
    let inviteCode: String
    let createdAt: Date?
    let createdBy: UUID
    let mode: String
    let intro: String?
    let coverColorHex: String?

    enum CodingKeys: String, CodingKey {
        case id, name, mode, intro
        case inviteCode = "invite_code"
        case createdAt = "created_at"
        case createdBy = "created_by"
        case coverColorHex = "cover_color_hex"
    }
}

struct DBGroupMember: Codable, Hashable, Identifiable {
    let id: UUID
    let groupId: UUID
    let userId: UUID
    let joinedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case groupId = "group_id"
        case userId = "user_id"
        case joinedAt = "joined_at"
    }
}
