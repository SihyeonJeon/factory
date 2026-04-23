import Foundation
import Network
import os

extension Notification.Name {
    static let offlineQueueDidFlushMemory = Notification.Name("offlineQueueDidFlushMemory")
}

struct PendingEventCreate: Codable, Hashable, Sendable {
    let groupId: UUID
    let title: String
    let startDate: Date
    let endDate: Date?
    let reminderAt: Date?
}

enum PendingOp: Codable, Hashable, Sendable {
    case createMemory(DBMemoryInsert)
    case createEvent(PendingEventCreate)

    private enum CodingKeys: String, CodingKey {
        case kind
        case memoryInsert
        case eventCreate
    }

    private enum Kind: String, Codable {
        case createMemory
        case createEvent
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Kind.self, forKey: .kind) {
        case .createMemory:
            self = .createMemory(try container.decode(DBMemoryInsert.self, forKey: .memoryInsert))
        case .createEvent:
            self = .createEvent(try container.decode(PendingEventCreate.self, forKey: .eventCreate))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .createMemory(insert):
            try container.encode(Kind.createMemory, forKey: .kind)
            try container.encode(insert, forKey: .memoryInsert)
        case let .createEvent(event):
            try container.encode(Kind.createEvent, forKey: .kind)
            try container.encode(event, forKey: .eventCreate)
        }
    }
}

@MainActor
final class OfflineQueue: ObservableObject {
    @Published private(set) var pendingCount: Int = 0

    private struct PendingItem: Codable, Identifiable, Hashable {
        let id: UUID
        let op: PendingOp
    }

    private static let storageKey = "unf.offline.queue"

    private let userDefaults: UserDefaults
    private let memoryRepository: MemoryRepository
    private let eventRepository: EventRepository
    private let logger = Logger(subsystem: "com.jeonsihyeon.memorymap", category: "OfflineQueue")
    private let monitorQueue = DispatchQueue(label: "com.jeonsihyeon.memorymap.offline-queue")
    private var items: [PendingItem]
    private var pathMonitor: NWPathMonitor?
    private var lastPathStatus: NWPath.Status?
    private var isFlushing = false

    init(
        userDefaults: UserDefaults = .standard,
        memoryRepository: MemoryRepository = SupabaseMemoryRepository(),
        eventRepository: EventRepository = SupabaseEventRepository()
    ) {
        self.userDefaults = userDefaults
        self.memoryRepository = memoryRepository
        self.eventRepository = eventRepository
        self.items = Self.loadItems(from: userDefaults)
        self.pendingCount = items.count
    }

    func enqueue(_ op: PendingOp) {
        items.append(PendingItem(id: UUID(), op: op))
        persist()
    }

    func flush() async {
        guard isFlushing == false, items.isEmpty == false else { return }

        isFlushing = true
        let snapshot = items
        defer { isFlushing = false }

        for item in snapshot {
            do {
                try await send(item.op)
                removeItem(id: item.id)
            } catch {
                logger.error("오프라인 큐 재전송 보류: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func startMonitoring() {
        guard pathMonitor == nil else { return }

        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let previous = self.lastPathStatus
                self.lastPathStatus = path.status
                if previous != .satisfied, path.status == .satisfied {
                    await self.flush()
                }
            }
        }
        monitor.start(queue: monitorQueue)
        pathMonitor = monitor
    }

    func pendingMemoryDrafts(for groupId: UUID) -> [DBMemory] {
        items.compactMap { item in
            guard case let .createMemory(insert) = item.op, insert.groupId == groupId else {
                return nil
            }
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
                createdAt: insert.capturedAt ?? insert.date,
                isDraft: true
            )
        }
        .sorted { $0.date > $1.date }
    }

    private func send(_ op: PendingOp) async throws {
        switch op {
        case let .createMemory(insert):
            let memory = try await memoryRepository.createMemory(insert)
            NotificationCenter.default.post(name: .offlineQueueDidFlushMemory, object: memory)
        case let .createEvent(payload):
            _ = try await eventRepository.createEvent(
                groupId: payload.groupId,
                title: payload.title,
                startDate: payload.startDate,
                endDate: payload.endDate,
                reminderAt: payload.reminderAt
            )
        }
    }

    private func removeItem(id: UUID) {
        items.removeAll { $0.id == id }
        persist()
    }

    private func persist() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(items)
            userDefaults.set(data, forKey: Self.storageKey)
        } catch {
            logger.error("오프라인 큐 저장 실패: \(error.localizedDescription, privacy: .public)")
        }
        pendingCount = items.count
    }

    private static func loadItems(from userDefaults: UserDefaults) -> [PendingItem] {
        guard let data = userDefaults.data(forKey: storageKey) else { return [] }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([PendingItem].self, from: data)
        } catch {
            return []
        }
    }
}

func isRecoverableNetworkError(_ error: Error) -> Bool {
    let nsError = error as NSError

    if nsError.domain == NSURLErrorDomain {
        let code = URLError.Code(rawValue: nsError.code)
        switch code {
        case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed, .timedOut:
            return true
        default:
            break
        }
    }

    if let urlError = error as? URLError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed, .timedOut:
            return true
        default:
            break
        }
    }

    return false
}
