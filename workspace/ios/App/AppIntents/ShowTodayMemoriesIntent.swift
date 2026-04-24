import AppIntents
import Foundation

struct ShowTodayMemoriesIntent: AppIntent {
    static let activityType = "com.jeonsihyeon.memorymap.shortcuts.showTodayMemories"
    static let deepLinkURL = URL(string: "unfading://rewind")!

    static var title: LocalizedStringResource = "오늘 추억 보여주기"
    static var description = IntentDescription("Open Unfading to today's rewind memories.")
    static var openAppWhenRun: Bool = true

    var targetURL: URL { Self.deepLinkURL }

    func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(targetURL))
    }
}
