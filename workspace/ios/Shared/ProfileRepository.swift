import Foundation
import Supabase

protocol ProfileRepository: Sendable {
    func fetchCurrent(userId: UUID) async throws -> DBProfile
    func updateDisplayName(_ name: String, userId: UUID) async throws -> DBProfile
    func updatePhotoURL(_ url: String?, userId: UUID) async throws -> DBProfile
    func updatePreferences(_ prefs: DBProfilePreferences, userId: UUID) async throws -> DBProfile
}

struct SupabaseProfileRepository: ProfileRepository {
    private var db: PostgrestClient { SupabaseService.shared.database }

    func fetchCurrent(userId: UUID) async throws -> DBProfile {
        return try await db.from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
    }

    func updateDisplayName(_ name: String, userId: UUID) async throws -> DBProfile {
        struct P: Encodable { let display_name: String }

        return try await db.from("profiles")
            .update(P(display_name: name))
            .eq("id", value: userId.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    func updatePhotoURL(_ url: String?, userId: UUID) async throws -> DBProfile {
        struct P: Encodable { let photo_url: String? }

        return try await db.from("profiles")
            .update(P(photo_url: url))
            .eq("id", value: userId.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    func updatePreferences(_ prefs: DBProfilePreferences, userId: UUID) async throws -> DBProfile {
        struct P: Encodable { let preferences: DBProfilePreferences }

        return try await db.from("profiles")
            .update(P(preferences: prefs))
            .eq("id", value: userId.uuidString)
            .select()
            .single()
            .execute()
            .value
    }
}
