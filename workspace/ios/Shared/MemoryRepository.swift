import Foundation
import Supabase

protocol MemoryRepository: Sendable {
    func fetchMemories(groupId: UUID) async throws -> [DBMemory]
    func searchMemories(groupId: UUID, query: String) async throws -> [DBMemory]
    func createMemory(_ insert: DBMemoryInsert) async throws -> DBMemory
    func updateMemory(id: UUID, title: String, note: String, emotions: [String]) async throws -> DBMemory
    func deleteMemory(id: UUID) async throws
}

struct SupabaseMemoryRepository: MemoryRepository {
    private var db: PostgrestClient { SupabaseService.shared.database }

    func fetchMemories(groupId: UUID) async throws -> [DBMemory] {
        return try await db.from("memories")
            .select()
            .eq("group_id", value: groupId.uuidString)
            .order("date", ascending: false)
            .execute()
            .value
    }

    func searchMemories(groupId: UUID, query: String) async throws -> [DBMemory] {
        guard let filter = Self.searchFilter(query: query) else {
            return []
        }

        return try await db.from("memories")
            .select()
            .eq("group_id", value: groupId.uuidString)
            .or(filter)
            .order("date", ascending: false)
            .execute()
            .value
    }

    func createMemory(_ insert: DBMemoryInsert) async throws -> DBMemory {
        return try await db.from("memories")
            .insert(insert, returning: .representation)
            .select()
            .single()
            .execute()
            .value
    }

    func updateMemory(id: UUID, title: String, note: String, emotions: [String]) async throws -> DBMemory {
        struct Patch: Encodable {
            let title: String
            let note: String
            let emotions: [String]
        }

        return try await db.from("memories")
            .update(Patch(title: title, note: note, emotions: emotions))
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteMemory(id: UUID) async throws {
        _ = try await db.from("memories")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}

extension SupabaseMemoryRepository {
    static func searchFilter(query: String) -> String? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let tag = trimmed.lowercased()
        return [
            "place_title.ilike.%\(trimmed)%",
            "note.ilike.%\(trimmed)%",
            "title.ilike.%\(trimmed)%",
            "categories.cs.{\(tag)}",
            "emotions.cs.{\(tag)}"
        ].joined(separator: ",")
    }
}
