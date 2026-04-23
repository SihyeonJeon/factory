import Foundation
import UserNotifications

struct NotificationBroadcaster {
    func sendPlanReminder(title: String) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else { return false }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = UnfadingLocalized.Calendar.broadcastToast
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "calendar_broadcast_\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        try? await center.add(request)
        return true
    }
}
