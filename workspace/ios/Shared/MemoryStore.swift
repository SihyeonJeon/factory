import Foundation
import os
import Supabase

@MainActor
final class MemoryStore: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }

    @Published private(set) var memories: [DBMemory] = []
    @Published private(set) var state: LoadState = .idle
    @Published private(set) var pendingIncomingMemoryId: UUID?

    private let repo: MemoryRepository
    private let offlineCacheURL: URL?
    private let pendingIncomingClearDelayNanoseconds: UInt64
    private let logger = Logger(subsystem: "com.jeonsihyeon.memorymap", category: "MemoryStore")
    private var currentUserId: UUID?
    private var pendingIncomingClearTask: Task<Void, Never>?

    init(
        repo: MemoryRepository = SupabaseMemoryRepository(),
        offlineCacheURL: URL? = nil,
        currentUserId: UUID? = nil,
        pendingIncomingClearDelay: TimeInterval = 3
    ) {
        self.repo = repo
        self.offlineCacheURL = offlineCacheURL
        self.currentUserId = currentUserId
        self.pendingIncomingClearDelayNanoseconds = UInt64(max(pendingIncomingClearDelay, 0) * 1_000_000_000)
    }

    #if DEBUG
    init(memories: [DBMemory]) {
        self.repo = PreviewMemoryRepository()
        self.offlineCacheURL = nil
        self.pendingIncomingClearDelayNanoseconds = 3_000_000_000
        self.memories = memories
        self.state = .loaded
    }

    func applyUITestStub(groupId: UUID) {
        memories = Self.uiTestStubMemories(groupId: groupId)
        state = .loaded
    }

    static func uiTestStubMemories(
        groupId: UUID = UUID(uuidString: "11111111-1111-4111-8111-111111111117")!,
        userId: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000017")!
    ) -> [DBMemory] {
        let eventId = UUID(uuidString: "99999999-9999-4999-8999-999999999991")!
        let participantIds = [
            userId,
            UUID(uuidString: "00000000-0000-0000-0000-000000000018")!,
            UUID(uuidString: "00000000-0000-0000-0000-000000000019")!
        ]

        return [
            DBMemory(
                id: UUID(uuidString: "eeeeeee1-eeee-4eee-8eee-eeeeeeeeeee1")!,
                userId: userId,
                groupId: groupId,
                eventId: eventId,
                title: "상수 루프톱 저녁",
                note: "친구들과 공연 이야기를 나눈 밤",
                placeTitle: "상수 루프톱",
                address: "서울 마포구",
                locationLat: 37.5519,
                locationLng: 126.9215,
                date: Date(timeIntervalSince1970: 1_776_000_000),
                capturedAt: Date(timeIntervalSince1970: 1_776_000_000),
                photoURL: nil,
                photoURLs: [],
                categories: ["food"],
                emotions: ["joy", "grateful"],
                participantUserIds: participantIds,
                cost: 68_000,
                reactionCount: 2,
                createdAt: Date(timeIntervalSince1970: 1_776_000_000)
            ),
            DBMemory(
                id: UUID(uuidString: "eeeeeee2-eeee-4eee-8eee-eeeeeeeeeee2")!,
                userId: userId,
                groupId: groupId,
                eventId: eventId,
                title: "한강 산책",
                note: "노을을 보며 천천히 걸었던 시간",
                placeTitle: "여의도 한강공원",
                address: "서울 영등포구",
                locationLat: 37.5283,
                locationLng: 126.9326,
                date: Date(timeIntervalSince1970: 1_776_086_400),
                capturedAt: Date(timeIntervalSince1970: 1_776_086_400),
                photoURL: nil,
                photoURLs: [],
                categories: ["walk"],
                emotions: ["calm", "nostalgic"],
                participantUserIds: participantIds,
                cost: 12_000,
                reactionCount: 1,
                createdAt: Date(timeIntervalSince1970: 1_776_086_400)
            ),
            DBMemory(
                id: UUID(uuidString: "eeeeeee3-eeee-4eee-8eee-eeeeeeeeeee3")!,
                userId: userId,
                groupId: groupId,
                eventId: eventId,
                title: "해돋이 산책",
                note: "차가운 아침 공기와 함께 걷던 시간",
                placeTitle: "광화문",
                address: "서울 종로구",
                locationLat: 37.5700,
                locationLng: 126.9768,
                date: Date(timeIntervalSince1970: 1_776_172_800),
                capturedAt: Date(timeIntervalSince1970: 1_776_172_800),
                photoURL: nil,
                photoURLs: [],
                categories: ["trip"],
                emotions: ["calm"],
                participantUserIds: [userId],
                cost: nil,
                reactionCount: 0,
                createdAt: Date(timeIntervalSince1970: 1_776_172_800)
            )
        ]
    }
    #endif

    var legacyDrafts: [SampleMemoryDraft] {
        memories.map { memory in
            SampleMemoryDraft(
                id: memory.id,
                title: memory.title,
                body: memory.note,
                placeName: memory.placeTitle,
                timestamp: memory.date,
                moodIDs: memory.emotions
            )
        }
    }

    var drafts: [SampleMemoryDraft] {
        legacyDrafts
    }

    func setCurrentUserId(_ userId: UUID?) {
        currentUserId = userId
    }

    func loadMemories(for groupId: UUID) async {
        state = .loading
        do {
            let fetched = try await repo.fetchMemories(groupId: groupId)
            memories = fetched
            try writeOfflineCache(fetched, groupId: groupId)
            state = .loaded
        } catch {
            logger.error("메모리 로드 실패: \(error.localizedDescription, privacy: .public)")
            if let cached = try? readOfflineCache(groupId: groupId) {
                memories = cached
                state = .loaded
            } else {
                state = .error(error.localizedDescription)
            }
        }
    }

    @discardableResult
    func createMemory(_ insert: DBMemoryInsert) async throws -> DBMemory {
        let created = try await repo.createMemory(insert)
        upsert(created)
        return created
    }

    @discardableResult
    func updateMemory(id: UUID, title: String, note: String, emotions: [String]) async throws -> DBMemory {
        let updated = try await repo.updateMemory(id: id, title: title, note: note, emotions: emotions)
        upsert(updated)
        return updated
    }

    func deleteMemory(id: UUID) async throws {
        try await repo.deleteMemory(id: id)
        memories.removeAll { $0.id == id }
    }

    func clearPendingIncomingMemory() {
        pendingIncomingClearTask?.cancel()
        pendingIncomingClearTask = nil
        pendingIncomingMemoryId = nil
    }

    func handleRealtimeInserted(_ memory: DBMemory) {
        upsert(memory)

        guard memory.userId != currentUserId else { return }
        announcePendingIncomingMemory(id: memory.id)
    }

    func subscribeRealtime(groupId: UUID) -> Task<Void, Never> {
        Task { [weak self] in
            guard let self else { return }

            let channel = SupabaseService.shared.realtime.channel("memories:\(groupId.uuidString)")
            let filter = RealtimePostgresFilter.eq("group_id", value: groupId)
            let insertions = channel.postgresChange(InsertAction.self, schema: "public", table: "memories", filter: filter)
            let updates = channel.postgresChange(UpdateAction.self, schema: "public", table: "memories", filter: filter)
            let deletes = channel.postgresChange(DeleteAction.self, schema: "public", table: "memories", filter: filter)

            do {
                try await channel.subscribeWithError()
            } catch {
                await MainActor.run {
                    self.logger.error("메모리 실시간 구독 실패: \(error.localizedDescription, privacy: .public)")
                }
                await SupabaseService.shared.realtime.removeChannel(channel)
                return
            }

            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    for await insertion in insertions {
                        guard !Task.isCancelled else { return }
                        do {
                            let memory = try insertion.decodeRecord(as: DBMemory.self, decoder: Self.supabaseDecoder())
                            await MainActor.run { self.handleRealtimeInserted(memory) }
                        } catch {
                            await MainActor.run {
                                self.logger.error("INSERT 메모리 디코드 실패: \(error.localizedDescription, privacy: .public)")
                            }
                        }
                    }
                }

                group.addTask {
                    for await update in updates {
                        guard !Task.isCancelled else { return }
                        do {
                            let memory = try update.decodeRecord(as: DBMemory.self, decoder: Self.supabaseDecoder())
                            await MainActor.run { self.upsert(memory) }
                        } catch {
                            await MainActor.run {
                                self.logger.error("UPDATE 메모리 디코드 실패: \(error.localizedDescription, privacy: .public)")
                            }
                        }
                    }
                }

                group.addTask {
                    for await deletion in deletes {
                        guard !Task.isCancelled else { return }
                        do {
                            let memory = try deletion.decodeOldRecord(as: DBMemory.self, decoder: Self.supabaseDecoder())
                            await MainActor.run { self.memories.removeAll { $0.id == memory.id } }
                        } catch {
                            await MainActor.run {
                                self.logger.error("DELETE 메모리 디코드 실패: \(error.localizedDescription, privacy: .public)")
                            }
                        }
                    }
                }

                await group.waitForAll()
            }

            await SupabaseService.shared.realtime.removeChannel(channel)
        }
    }

    private func upsert(_ memory: DBMemory) {
        if let index = memories.firstIndex(where: { $0.id == memory.id }) {
            memories[index] = memory
        } else {
            memories.insert(memory, at: 0)
        }
        memories.sort { $0.date > $1.date }
    }

    private func announcePendingIncomingMemory(id: UUID) {
        pendingIncomingClearTask?.cancel()
        pendingIncomingMemoryId = id

        pendingIncomingClearTask = Task { [weak self] in
            guard let self else { return }

            if self.pendingIncomingClearDelayNanoseconds > 0 {
                try? await Task.sleep(nanoseconds: self.pendingIncomingClearDelayNanoseconds)
            }
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard self.pendingIncomingMemoryId == id else {
                    self.pendingIncomingClearTask = nil
                    return
                }
                self.pendingIncomingMemoryId = nil
                self.pendingIncomingClearTask = nil
            }
        }
    }

    private func writeOfflineCache(_ memories: [DBMemory], groupId: UUID) throws {
        let url = cacheURL(for: groupId)
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(memories)
        try data.write(to: url, options: [.atomic])
    }

    private func readOfflineCache(groupId: UUID) throws -> [DBMemory] {
        let data = try Data(contentsOf: cacheURL(for: groupId))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([DBMemory].self, from: data)
    }

    private func cacheURL(for groupId: UUID) -> URL {
        if let offlineCacheURL {
            return offlineCacheURL
        }

        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return documents.appendingPathComponent("memory-cache-\(groupId.uuidString)").appendingPathExtension("json")
    }

    nonisolated private static func supabaseDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

#if DEBUG
struct PreviewMemoryRepository: MemoryRepository {
    func fetchMemories(groupId: UUID) async throws -> [DBMemory] { [] }

    func createMemory(_ insert: DBMemoryInsert) async throws -> DBMemory {
        DBMemory(
            id: insert.id,
            userId: insert.userId,
            groupId: insert.groupId,
            eventId: insert.eventId,
            title: insert.title,
            note: insert.note,
            placeTitle: insert.placeTitle,
            address: insert.address,
            locationLat: insert.locationLat,
            locationLng: insert.locationLng,
            date: insert.date,
            capturedAt: insert.capturedAt,
            photoURL: insert.photoURL,
            photoURLs: insert.photoURLs,
            categories: insert.categories,
            emotions: insert.emotions,
            participantUserIds: insert.participantUserIds,
            cost: insert.cost,
            reactionCount: 0,
            createdAt: Date()
        )
    }

    func updateMemory(id: UUID, title: String, note: String, emotions: [String]) async throws -> DBMemory {
        DBMemory(
            id: id,
            userId: UUID(),
            groupId: UUID(),
            title: title,
            note: note,
            placeTitle: "",
            address: nil,
            locationLat: 0,
            locationLng: 0,
            date: Date(),
            capturedAt: nil,
            photoURL: nil,
            photoURLs: [],
            categories: [],
            emotions: emotions,
            reactionCount: 0,
            createdAt: nil
        )
    }

    func deleteMemory(id: UUID) async throws {}
}
#endif
