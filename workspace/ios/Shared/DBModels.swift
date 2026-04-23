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

struct DBMemory: Codable, Hashable, Identifiable {
    let id: UUID
    let userId: UUID
    let groupId: UUID
    let title: String
    let note: String
    let placeTitle: String
    let address: String?
    let locationLat: Double
    let locationLng: Double
    let date: Date
    let capturedAt: Date?
    let photoURL: String?
    let photoURLs: [String]
    let categories: [String]
    let emotions: [String]
    let reactionCount: Int
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, note, date, address, categories, emotions
        case userId = "user_id"
        case groupId = "group_id"
        case placeTitle = "place_title"
        case locationLat = "location_lat"
        case locationLng = "location_lng"
        case capturedAt = "captured_at"
        case photoURL = "photo_url"
        case photoURLs = "photo_urls"
        case reactionCount = "reaction_count"
        case createdAt = "created_at"
    }
}

struct DBMemoryInsert: Encodable {
    let id: UUID
    let userId: UUID
    let groupId: UUID
    let title: String
    let note: String
    let placeTitle: String
    let address: String?
    let locationLat: Double
    let locationLng: Double
    let date: Date
    let capturedAt: Date?
    let photoURL: String?
    let photoURLs: [String]
    let categories: [String]
    let emotions: [String]

    enum CodingKeys: String, CodingKey {
        case id, title, note, date, address, categories, emotions
        case userId = "user_id"
        case groupId = "group_id"
        case placeTitle = "place_title"
        case locationLat = "location_lat"
        case locationLng = "location_lng"
        case capturedAt = "captured_at"
        case photoURL = "photo_url"
        case photoURLs = "photo_urls"
    }
}
