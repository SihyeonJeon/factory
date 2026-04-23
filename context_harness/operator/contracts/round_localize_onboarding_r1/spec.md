# r12 spec base 082e205
## Deliverables
1. Shared/SampleModels.swift — replace English strings in samples with Korean (SampleMemoryPin titles/shortLabels; RewindMoment titles/locations/summaries/people/mood; GroupPreview names/members/summary)
2. Features/Onboarding/OnboardingView.swift (NEW): 3 TabView slides (welcome, place-first, group-sharing), each with hero icon + Korean title + body, dismiss button "시작하기" persists prefs.hasSeenOnboarding
3. Shared/UnfadingEmptyState.swift (NEW reusable): icon + title + body + optional CTA
4. Apply UnfadingEmptyState in: MemoryMapHomeView (sheet's summary when no memories — but currently always has samples so conditional on MemoryStore count), RewindFeedView empty, CalendarView empty (already has similar → migrate to UnfadingEmptyState), ComposerState.saveEnabled empty-photo + note state guidance
5. App/MemoryMapApp.swift: wrap in conditional on @StateObject var prefs.hasSeenOnboarding → show OnboardingView or RootTabView
6. UnfadingLocalized.Onboarding + EmptyState sections
7. Tests: OnboardingPersistenceTest, EmptyStateBuildTest (≥ 2)

Also update tests that assert English sample data (MemoryDetailTests, MemoryCalendarStoreTests may rely on IDs not strings — verify)
