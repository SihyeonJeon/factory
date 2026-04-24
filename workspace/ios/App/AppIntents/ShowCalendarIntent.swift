import AppIntents
import Foundation

struct ShowCalendarIntent: AppIntent {
    static let activityType = "com.jeonsihyeon.memorymap.shortcuts.showCalendar"
    static let deepLinkURL = URL(string: "unfading://calendar")!

    static var title: LocalizedStringResource = "이번 달 캘린더 보여주기"
    static var description = IntentDescription("Open Unfading to the calendar tab for this month.")
    static var openAppWhenRun: Bool = true

    var targetURL: URL { Self.deepLinkURL }

    func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(targetURL))
    }
}
