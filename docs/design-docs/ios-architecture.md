# iOS Architecture — Unfading

**Date:** 2026-04-14

## Structure

```
workspace/ios/
├── App/
│   ├── UnfadingApp.swift          — @main, environment injection, sample data seeding
│   └── RootTabView.swift          — 3 tabs: 지도 / 캘린더 / 설정
├── Features/
│   ├── Home/
│   │   ├── UnfadingHomeView.swift  — Map + bottom sheet + search + FAB
│   │   ├── MainBottomSheet.swift   — Custom overlay sheet with snap points
│   │   ├── MemoryBriefView.swift   — 추억 간략히 보기
│   │   ├── MemoryDetailView.swift  — 추억 상세 보기
│   │   ├── MemoryGalleryView.swift — Photo grid by date
│   │   ├── MemoryPinMarker.swift   — Single pin / photo marker
│   │   ├── MemoryClusterMapView.swift — MKMapView with clustering
│   │   ├── MemoryComposerSheet.swift — 추억 만들기
│   │   └── MemoryAnnotation.swift  — MKAnnotation wrapper
│   ├── Calendar/
│   │   ├── CalendarView.swift      — Monthly calendar + day memories
│   │   ├── MonthlyCalendarGrid.swift — LazyVGrid month view
│   │   └── DayMemoriesList.swift   — Memories for selected day
│   └── Settings/
│       └── SettingsView.swift      — Groups, premium, app info
├── Shared/
│   ├── UnfadingTheme.swift         — Centralized color palette
│   ├── Domain/
│   │   ├── DomainModels.swift      — DomainMemory, DomainGroup, DomainEvent
│   │   ├── MemoryStore.swift       — @Observable memory storage
│   │   ├── GroupStore.swift        — @Observable group storage
│   │   └── EventStore.swift        — @Observable event storage
│   ├── LocationPermissionStore.swift — CLLocationManager wrapper
│   ├── PlaceSearchService.swift    — MKLocalSearch wrapper
│   ├── PhotoLoader.swift           — PHAsset image loading + cache
│   ├── AsyncPhotoView.swift        — Reusable photo view component
│   ├── SampleModels.swift          — 20 dummy memories for testing
│   ├── TabRouter.swift             — AppTab enum + selection
│   ├── SupabaseManager.swift       — Client singleton (canImport guard)
│   ├── SupabaseSync.swift          — Sync service
│   └── AuthManager.swift           — Auth state
└── Tests/
    └── UnfadingTests.swift         — 79 unit tests
```

## Design Principles

- **Map-first:** Home screen is always a map with bottom sheet overlay
- **Korean-first:** All UI text in Korean, no `.lproj`
- **Light-mode only:** `.preferredColorScheme(.light)` (dark mode future work)
- **UnfadingTheme:** All colors from centralized palette, no inline colors
- **Semantic fonts:** Dynamic Type compliant, no hardcoded sizes
- **44pt touch targets:** Every interactive element, enforced by HIG evaluation
- **VoiceOver:** Accessibility labels on all interactive elements
