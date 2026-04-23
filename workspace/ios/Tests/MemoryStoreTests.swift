import XCTest
@testable import MemoryMap

@MainActor
final class MemoryStoreTests: XCTestCase {
    func test_create_addsToMemoriesList() async throws {
        let repo = InMemoryMemoryRepository()
        let store = MemoryStore(repo: repo, offlineQueue: makeOfflineQueue(), offlineCacheURL: tempURL())

        let created = try await store.createMemory(Self.insert())

        XCTAssertEqual(store.memories.first?.id, created.id)
        XCTAssertEqual(store.memories.count, 1)
    }

    func test_update_mutatesRow() async throws {
        let initial = Self.memory(title: "이전 제목", note: "이전 노트", emotions: ["calm"])
        let repo = InMemoryMemoryRepository(memories: [initial])
        let store = MemoryStore(repo: repo, offlineQueue: makeOfflineQueue(), offlineCacheURL: tempURL())
        await store.loadMemories(for: initial.groupId)

        let updated = try await store.updateMemory(id: initial.id, title: "새 제목", note: "새 노트", emotions: ["joy"])

        XCTAssertEqual(updated.title, "새 제목")
        XCTAssertEqual(store.memories.first?.note, "새 노트")
        XCTAssertEqual(store.memories.first?.emotions, ["joy"])
    }

    func test_delete_removesRow() async throws {
        let initial = Self.memory()
        let repo = InMemoryMemoryRepository(memories: [initial])
        let store = MemoryStore(repo: repo, offlineQueue: makeOfflineQueue(), offlineCacheURL: tempURL())
        await store.loadMemories(for: initial.groupId)

        try await store.deleteMemory(id: initial.id)

        XCTAssertTrue(store.memories.isEmpty)
    }

    func test_loadMemories_emptyState() async {
        let groupId = UUID()
        let repo = InMemoryMemoryRepository(memories: [])
        let store = MemoryStore(repo: repo, offlineQueue: makeOfflineQueue(), offlineCacheURL: tempURL())

        await store.loadMemories(for: groupId)

        XCTAssertEqual(store.memories, [])
        XCTAssertEqual(store.state, .loaded)
    }

    func test_offlineCache_roundTripsAfterFetchFailure() async {
        let groupId = UUID()
        let cached = Self.memory(groupId: groupId, title: "캐시된 추억")
        let cacheURL = tempURL()
        let repo = InMemoryMemoryRepository(memories: [cached])
        let writer = MemoryStore(repo: repo, offlineQueue: makeOfflineQueue(), offlineCacheURL: cacheURL)
        await writer.loadMemories(for: groupId)
        await repo.setShouldFail(true)

        let reader = MemoryStore(repo: repo, offlineQueue: makeOfflineQueue(), offlineCacheURL: cacheURL)
        await reader.loadMemories(for: groupId)

        XCTAssertEqual(reader.memories, [cached])
        XCTAssertEqual(reader.state, .loaded)
    }

    func test_handleRealtimeInserted_setsPendingIncomingMemoryIdForOtherUser_andClearsAfterDelay() async throws {
        let currentUserId = UUID(uuidString: "00000000-0000-0000-0000-000000000017")!
        let incomingUserId = UUID(uuidString: "00000000-0000-0000-0000-000000000018")!
        let incoming = Self.memory(
            id: UUID(uuidString: "eeeeeee4-eeee-4eee-8eee-eeeeeeeeeee4")!,
            userId: incomingUserId,
            title: "새로 도착한 추억",
            note: "실시간으로 들어온 기록",
            emotions: ["joy"]
        )
        let store = MemoryStore(
            repo: InMemoryMemoryRepository(),
            offlineQueue: makeOfflineQueue(),
            offlineCacheURL: tempURL(),
            currentUserId: currentUserId,
            pendingIncomingClearDelay: 0.05
        )

        store.handleRealtimeInserted(incoming)

        XCTAssertEqual(store.memories.first?.id, incoming.id)
        XCTAssertEqual(store.pendingIncomingMemoryId, incoming.id)

        try await Task.sleep(nanoseconds: 120_000_000)

        XCTAssertNil(store.pendingIncomingMemoryId)
    }

    func test_handleRealtimeInserted_fromCurrentUser_doesNotSetPendingIncomingMemoryId() {
        let currentUserId = UUID(uuidString: "00000000-0000-0000-0000-000000000017")!
        let store = MemoryStore(
            repo: InMemoryMemoryRepository(),
            offlineQueue: makeOfflineQueue(),
            offlineCacheURL: tempURL(),
            currentUserId: currentUserId,
            pendingIncomingClearDelay: 0.05
        )
        let ownMemory = Self.memory(id: UUID(uuidString: "eeeeeee5-eeee-4eee-8eee-eeeeeeeeeee5")!)

        store.handleRealtimeInserted(ownMemory)

        XCTAssertEqual(store.memories.first?.id, ownMemory.id)
        XCTAssertNil(store.pendingIncomingMemoryId)
    }

    func test_createMemory_offline_enqueuesDraftAndReturnsDraftMemory() async throws {
        let repo = InMemoryMemoryRepository()
        await repo.setShouldFail(true)
        let queue = makeOfflineQueue()
        let store = MemoryStore(repo: repo, offlineQueue: queue, offlineCacheURL: tempURL())

        let created = try await store.createMemory(Self.insert())

        XCTAssertEqual(created.id, store.memories.first?.id)
        XCTAssertEqual(store.memories.first?.isDraft, true)
        XCTAssertEqual(queue.pendingCount, 1)
    }

    private func tempURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
    }

    private func makeOfflineQueue() -> OfflineQueue {
        let suiteName = "MemoryStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return OfflineQueue(
            userDefaults: defaults,
            memoryRepository: InMemoryMemoryRepository(),
            eventRepository: StubQueueEventRepository()
        )
    }

    private static func insert(
        userId: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000017")!,
        groupId: UUID = UUID(uuidString: "11111111-1111-4111-8111-111111111117")!
    ) -> DBMemoryInsert {
        DBMemoryInsert(
            id: UUID(),
            userId: userId,
            groupId: groupId,
            eventId: nil,
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
            emotions: ["joy"],
            participantUserIds: [],
            cost: nil
        )
    }

    private static func memory(
        id: UUID = UUID(),
        userId: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000017")!,
        groupId: UUID = UUID(uuidString: "11111111-1111-4111-8111-111111111117")!,
        title: String = "상수 루프톱 저녁",
        note: String = "친구들과 공연 이야기를 나눈 밤",
        emotions: [String] = ["joy"]
    ) -> DBMemory {
        DBMemory(
            id: id,
            userId: userId,
            groupId: groupId,
            title: title,
            note: note,
            placeTitle: "상수 루프톱",
            address: "서울 마포구",
            locationLat: 37.5519,
            locationLng: 126.9215,
            date: Date(timeIntervalSince1970: 1_776_000_000),
            capturedAt: Date(timeIntervalSince1970: 1_776_000_000),
            photoURL: nil,
            photoURLs: [],
            categories: ["food"],
            emotions: emotions,
            reactionCount: 0,
            createdAt: Date(timeIntervalSince1970: 1_776_000_000)
        )
    }
}

private struct StubQueueEventRepository: EventRepository {
    func plannedEvents(groupId: UUID, startUTC: Date, endUTC: Date) async throws -> [DBEvent] { [] }
    func monthlyExpenseKST(groupId: UUID, year: Int, month: Int) async throws -> Int64 { 0 }
    func createEvent(groupId: UUID, title: String, startDate: Date, endDate: Date?, reminderAt: Date?) async throws -> DBEvent {
        DBEvent(id: UUID(), groupId: groupId, title: title, startDate: startDate, endDate: endDate, isMultiDay: endDate != nil, createdAt: nil, reminderAt: reminderAt)
    }
    func findEventAt(groupId: UUID, timestamp: Date) async throws -> DBEvent? { nil }
}

private actor InMemoryMemoryRepository: MemoryRepository {
    private var memories: [DBMemory]
    private var shouldFail = false

    init(memories: [DBMemory] = []) {
        self.memories = memories
    }

    func setShouldFail(_ value: Bool) {
        shouldFail = value
    }

    func fetchMemories(groupId: UUID) async throws -> [DBMemory] {
        if shouldFail { throw URLError(.notConnectedToInternet) }
        return memories
            .filter { $0.groupId == groupId }
            .sorted { $0.date > $1.date }
    }

    func createMemory(_ insert: DBMemoryInsert) async throws -> DBMemory {
        if shouldFail { throw URLError(.notConnectedToInternet) }
        let memory = DBMemory(
            id: insert.id,
            userId: insert.userId,
            groupId: insert.groupId,
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
            reactionCount: 0,
            createdAt: Date(timeIntervalSince1970: 1_776_000_000)
        )
        memories.insert(memory, at: 0)
        return memory
    }

    func updateMemory(id: UUID, title: String, note: String, emotions: [String]) async throws -> DBMemory {
        if shouldFail { throw URLError(.notConnectedToInternet) }
        guard let index = memories.firstIndex(where: { $0.id == id }) else {
            throw URLError(.badServerResponse)
        }

        let current = memories[index]
        let updated = DBMemory(
            id: current.id,
            userId: current.userId,
            groupId: current.groupId,
            title: title,
            note: note,
            placeTitle: current.placeTitle,
            address: current.address,
            locationLat: current.locationLat,
            locationLng: current.locationLng,
            date: current.date,
            capturedAt: current.capturedAt,
            photoURL: current.photoURL,
            photoURLs: current.photoURLs,
            categories: current.categories,
            emotions: emotions,
            reactionCount: current.reactionCount,
            createdAt: current.createdAt
        )
        memories[index] = updated
        return updated
    }

    func deleteMemory(id: UUID) async throws {
        if shouldFail { throw URLError(.notConnectedToInternet) }
        memories.removeAll { $0.id == id }
    }
}
