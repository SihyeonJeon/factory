import AppIntents

struct UnfadingShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ShowTodayMemoriesIntent(),
            phrases: [
                "\(AppShortcutPhraseToken.applicationName)에서 오늘 추억 보여줘",
                "Show today's memories in \(AppShortcutPhraseToken.applicationName)"
            ],
            shortTitle: "오늘 추억",
            systemImageName: "sparkles.rectangle.stack"
        )

        AppShortcut(
            intent: NewMemoryIntent(),
            phrases: [
                "\(AppShortcutPhraseToken.applicationName)에서 새 추억 기록해줘",
                "Record a new memory in \(AppShortcutPhraseToken.applicationName)"
            ],
            shortTitle: "새 추억",
            systemImageName: "plus.circle"
        )

        AppShortcut(
            intent: ShowCalendarIntent(),
            phrases: [
                "\(AppShortcutPhraseToken.applicationName)에서 이번 달 캘린더 보여줘",
                "Show this month's calendar in \(AppShortcutPhraseToken.applicationName)"
            ],
            shortTitle: "캘린더",
            systemImageName: "calendar"
        )
    }
}
