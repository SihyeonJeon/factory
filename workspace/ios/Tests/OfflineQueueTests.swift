import XCTest
@testable import MemoryMap

@MainActor
final class OfflineQueueTests: XCTestCase {
    func test_enqueue_persistsAcrossInstances() {
        let suiteName = "OfflineQueueTests.persist.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let memoryRepo = QueueMemoryRepository()
        let eventRepo = QueueEventRepository()
        let queue = OfflineQueue(userDefaults: defaults, memoryRepository: memoryRepo, eventRepository: eventRepo)

        queue.enqueue(.createMemory(Self.insert()))

        let restored = OfflineQueue(userDefaults: defaults, memoryRepository: memoryRepo, eventRepository: eventRepo)
        XCTAssertEqual(restored.pendingCount, 1)
    }

    func test_flush_removesOnlySuccessfulItems() async throws {
        let suiteName = "OfflineQueueTests.flush.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let memoryRepo = QueueMemoryRepository()
        let eventRepo = QueueEventRepository()
        let queue = OfflineQueue(userDefaults: defaults, memoryRepository: memoryRepo, eventRepository: eventRepo)
        queue.enqueue(.createMemory(Self.insert()))
        queue.enqueue(
            .createEvent(
                PendingEventCreate(
                    groupId: UUID(uuidString: "11111111-1111-4111-8111-111111111117")!,
                    title: "대기 이벤트",
                    startDate: Date(timeIntervalSince1970: 1_776_000_000),
                    endDate: nil,
                    reminderAt: nil
                )
            )
        )

        await eventRepo.setShouldFail(true)
        await queue.flush()

        let stored = OfflineQueue(userDefaults: defaults, memoryRepository: memoryRepo, eventRepository: eventRepo)
        let createdMemories = await memoryRepo.createdMemoryIds()

        XCTAssertEqual(createdMemories.count, 1)
        XCTAssertEqual(stored.pendingCount, 1)
    }

    private static func insert() -> DBMemoryInsert {
        DBMemoryInsert(
            id: UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!,
            userId: UUID(uuidString: "00000000-0000-0000-0000-000000000017")!,
            groupId: UUID(uuidString: "11111111-1111-4111-8111-111111111117")!,
            eventId: nil,
            title: "오프라인 추억",
            note: "연결이 없을 때 저장",
            placeTitle: "합정",
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
}

private actor QueueMemoryRepository: MemoryRepository {
    private var createdIds: [UUID] = []

    func fetchMemories(groupId: UUID) async throws -> [DBMemory] { [] }
    func searchMemories(groupId: UUID, query: String) async throws -> [DBMemory] { [] }

    func createMemory(_ insert: DBMemoryInsert) async throws -> DBMemory {
        createdIds.append(insert.id)
        return DBMemory(
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
            createdAt: insert.date
        )
    }

    func updateMemory(id: UUID, title: String, note: String, emotions: [String]) async throws -> DBMemory {
        throw URLError(.unsupportedURL)
    }

    func deleteMemory(id: UUID) async throws {}

    func createdMemoryIds() -> [UUID] {
        createdIds
    }
}

private actor QueueEventRepository: EventRepository {
    private var shouldFail = false

    func plannedEvents(groupId: UUID, startUTC: Date, endUTC: Date) async throws -> [DBEvent] { [] }
    func monthlyExpenseKST(groupId: UUID, year: Int, month: Int) async throws -> Int64 { 0 }

    func createEvent(groupId: UUID, title: String, startDate: Date, endDate: Date?, reminderAt: Date?) async throws -> DBEvent {
        if shouldFail {
            throw URLError(.notConnectedToInternet)
        }
        return DBEvent(id: UUID(), groupId: groupId, title: title, startDate: startDate, endDate: endDate, isMultiDay: endDate != nil, createdAt: nil, reminderAt: reminderAt)
    }

    func findEventAt(groupId: UUID, timestamp: Date) async throws -> DBEvent? { nil }
    func fetchEvent(groupId: UUID, eventId: UUID) async throws -> DBEvent? { nil }

    func setShouldFail(_ value: Bool) {
        shouldFail = value
    }
}
