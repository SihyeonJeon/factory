import AppIntents
import Foundation

struct NewMemoryIntent: AppIntent {
    static let activityType = "com.jeonsihyeon.memorymap.shortcuts.newMemory"
    static let deepLinkURL = URL(string: "unfading://composer")!

    static var title: LocalizedStringResource = "새 추억 기록"
    static var description = IntentDescription("Open Unfading and start a new memory.")
    static var openAppWhenRun: Bool = true

    var targetURL: URL { Self.deepLinkURL }

    func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(targetURL))
    }
}
