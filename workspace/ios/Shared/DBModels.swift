import Foundation

struct DBProfilePreferences: Codable, Hashable, Sendable {
    var reminderEnabled: Bool = false
    var themePreference: String = "system"

    enum CodingKeys: String, CodingKey {
        case reminderEnabled = "reminder_enabled"
        case themePreference = "theme_preference"
    }

    init(reminderEnabled: Bool = false, themePreference: String = "system") {
        self.reminderEnabled = reminderEnabled
        self.themePreference = themePreference
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .reminderEnabled) ?? false
        themePreference = try container.decodeIfPresent(String.self, forKey: .themePreference) ?? "system"
    }
}

struct DBProfile: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    let email: String?
    let displayName: String?
    let photoURL: String?
    let preferences: DBProfilePreferences
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, email, preferences
        case displayName = "display_name"
        case photoURL = "photo_url"
        case createdAt = "created_at"
    }

    init(
        id: UUID,
        email: String?,
        displayName: String?,
        photoURL: String?,
        preferences: DBProfilePreferences = DBProfilePreferences(),
        createdAt: Date?
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.preferences = preferences
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        photoURL = try container.decodeIfPresent(String.self, forKey: .photoURL)
        preferences = try container.decodeIfPresent(DBProfilePreferences.self, forKey: .preferences) ?? DBProfilePreferences()
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
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
