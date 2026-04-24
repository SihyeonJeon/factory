import BackgroundTasks
import Foundation
import UserNotifications

final class BackgroundSyncController {
    static let shared = BackgroundSyncController()

    static let refreshTaskIdentifier = "com.jeonsihyeon.memorymap.refresh"
    static let rewindTaskIdentifier = "com.jeonsihyeon.memorymap.rewind"
    static let rewindNotificationIdentifierPrefix = "monthly_rewind"
    static let rewindNotificationBody = "이번 달 리와인드 준비됐어요"

    private enum Keys {
        static let activeGroupId = "background.sync.active.group.id"
        static let scheduledRewindMonth = "background.sync.rewind.scheduled.month"
    }

    private weak var offlineQueue: OfflineQueue?
    private weak var memoryStore: MemoryStore?
    private let userDefaults: UserDefaults
    private var didRegister = false

    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func register() {
        guard didRegister == false else { return }
        didRegister = true

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.refreshTaskIdentifier,
            using: nil
        ) { task in
            guard let task = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            Task { @MainActor in
                self.handleAppRefresh(task)
            }
        }

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.rewindTaskIdentifier,
            using: nil
        ) { task in
            guard let task = task as? BGProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }
            Task { @MainActor in
                self.handleRewindProcessing(task)
            }
        }

        scheduleAppRefresh()
        scheduleRewindProcessing()
    }

    @MainActor
    func configure(offlineQueue: OfflineQueue, memoryStore: MemoryStore) {
        self.offlineQueue = offlineQueue
        self.memoryStore = memoryStore
    }

    @MainActor
    func setActiveGroupId(_ groupId: UUID?) {
        if let groupId {
            userDefaults.set(groupId.uuidString, forKey: Keys.activeGroupId)
        } else {
            userDefaults.removeObject(forKey: Keys.activeGroupId)
        }
    }

    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.refreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    func scheduleRewindProcessing() {
        let request = BGProcessingTaskRequest(identifier: Self.rewindTaskIdentifier)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60 * 12)
        try? BGTaskScheduler.shared.submit(request)
    }

    private func handleAppRefresh(_ task: BGAppRefreshTask) {
        scheduleAppRefresh()

        let operation = Task { @MainActor in
            guard let offlineQueue, let memoryStore, let groupId = activeGroupId else {
                return false
            }

            guard Task.isCancelled == false else { return false }
            await offlineQueue.flush()
            guard Task.isCancelled == false else { return false }
            await memoryStore.loadMemories(for: groupId)
            return Task.isCancelled == false
        }

        task.expirationHandler = {
            operation.cancel()
        }

        Task {
            let success = await operation.value
            task.setTaskCompleted(success: success)
        }
    }

    private func handleRewindProcessing(_ task: BGProcessingTask) {
        scheduleRewindProcessing()

        let operation = Task { @MainActor in
            await scheduleMonthlyRewindNotificationIfNeeded()
        }

        task.expirationHandler = {
            operation.cancel()
        }

        Task {
            let success = await operation.value
            task.setTaskCompleted(success: success)
        }
    }

    private var activeGroupId: UUID? {
        guard let rawValue = userDefaults.string(forKey: Keys.activeGroupId) else {
            return nil
        }
        return UUID(uuidString: rawValue)
    }

    private func scheduleMonthlyRewindNotificationIfNeeded() async -> Bool {
        let now = Date()
        guard isEndOfMonth(now) else { return true }

        let monthKey = monthIdentifier(for: now)
        guard userDefaults.string(forKey: Keys.scheduledRewindMonth) != monthKey else {
            return true
        }

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus) else {
            return false
        }

        let content = UNMutableNotificationContent()
        content.title = "리와인드"
        content.body = Self.rewindNotificationBody
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "\(Self.rewindNotificationIdentifierPrefix).\(monthKey)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        )

        do {
            try await center.add(request)
            userDefaults.set(monthKey, forKey: Keys.scheduledRewindMonth)
            return true
        } catch {
            return false
        }
    }

    private func isEndOfMonth(_ date: Date) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        guard let day = calendar.dateComponents([.day], from: date).day,
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return false
        }
        return day == range.count
    }

    private func monthIdentifier(for date: Date) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        return String(format: "%04d-%02d", year, month)
    }
}
