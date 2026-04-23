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
    let nickname: String?
    let joinedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, nickname
        case groupId = "group_id"
        case userId = "user_id"
        case joinedAt = "joined_at"
    }
}

struct DBGroupMemberWithProfile: Codable, Hashable, Identifiable {
    let id: UUID
    let nickname: String?
    let profiles: DBProfile
}

struct DBMemory: Codable, Hashable, Identifiable {
    let id: UUID
    let userId: UUID
    let groupId: UUID
    let eventId: UUID?
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
    let participantUserIds: [UUID]
    let cost: Int?
    let reactionCount: Int
    let createdAt: Date?
    let isDraft: Bool

    enum CodingKeys: String, CodingKey {
        case id, title, note, date, address, categories, emotions
        case cost
        case userId = "user_id"
        case groupId = "group_id"
        case eventId = "event_id"
        case placeTitle = "place_title"
        case locationLat = "location_lat"
        case locationLng = "location_lng"
        case capturedAt = "captured_at"
        case photoURL = "photo_url"
        case photoURLs = "photo_urls"
        case participantUserIds = "participant_user_ids"
        case reactionCount = "reaction_count"
        case createdAt = "created_at"
        case isDraft = "is_draft"
    }

    init(
        id: UUID,
        userId: UUID,
        groupId: UUID,
        eventId: UUID? = nil,
        title: String,
        note: String,
        placeTitle: String,
        address: String?,
        locationLat: Double,
        locationLng: Double,
        date: Date,
        capturedAt: Date?,
        photoURL: String?,
        photoURLs: [String],
        categories: [String],
        emotions: [String],
        participantUserIds: [UUID] = [],
        cost: Int? = nil,
        reactionCount: Int,
        createdAt: Date?,
        isDraft: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.groupId = groupId
        self.eventId = eventId
        self.title = title
        self.note = note
        self.placeTitle = placeTitle
        self.address = address
        self.locationLat = locationLat
        self.locationLng = locationLng
        self.date = date
        self.capturedAt = capturedAt
        self.photoURL = photoURL
        self.photoURLs = photoURLs
        self.categories = categories
        self.emotions = emotions
        self.participantUserIds = participantUserIds
        self.cost = cost
        self.reactionCount = reactionCount
        self.createdAt = createdAt
        self.isDraft = isDraft
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        groupId = try container.decode(UUID.self, forKey: .groupId)
        eventId = try container.decodeIfPresent(UUID.self, forKey: .eventId)
        title = try container.decode(String.self, forKey: .title)
        note = try container.decode(String.self, forKey: .note)
        placeTitle = try container.decode(String.self, forKey: .placeTitle)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        locationLat = try container.decode(Double.self, forKey: .locationLat)
        locationLng = try container.decode(Double.self, forKey: .locationLng)
        date = try container.decode(Date.self, forKey: .date)
        capturedAt = try container.decodeIfPresent(Date.self, forKey: .capturedAt)
        photoURL = try container.decodeIfPresent(String.self, forKey: .photoURL)
        photoURLs = try container.decodeIfPresent([String].self, forKey: .photoURLs) ?? []
        categories = try container.decodeIfPresent([String].self, forKey: .categories) ?? []
        emotions = try container.decodeIfPresent([String].self, forKey: .emotions) ?? []
        participantUserIds = try container.decodeIfPresent([UUID].self, forKey: .participantUserIds) ?? []
        cost = try container.decodeIfPresent(Int.self, forKey: .cost)
        reactionCount = try container.decodeIfPresent(Int.self, forKey: .reactionCount) ?? 0
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        isDraft = try container.decodeIfPresent(Bool.self, forKey: .isDraft) ?? false
    }
}

struct DBEvent: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    let groupId: UUID
    let title: String
    let startDate: Date
    let endDate: Date?
    let isMultiDay: Bool
    let createdAt: Date?
    let reminderAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title
        case groupId = "group_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case isMultiDay = "is_multi_day"
        case createdAt = "created_at"
        case reminderAt = "reminder_at"
    }
}

struct DBMemoryInsert: Codable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    let groupId: UUID
    let eventId: UUID?
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
    let participantUserIds: [UUID]
    let cost: Int?

    enum CodingKeys: String, CodingKey {
        case id, title, note, date, address, categories, emotions
        case cost
        case userId = "user_id"
        case groupId = "group_id"
        case eventId = "event_id"
        case placeTitle = "place_title"
        case locationLat = "location_lat"
        case locationLng = "location_lng"
        case capturedAt = "captured_at"
        case photoURL = "photo_url"
        case photoURLs = "photo_urls"
        case participantUserIds = "participant_user_ids"
    }
}
