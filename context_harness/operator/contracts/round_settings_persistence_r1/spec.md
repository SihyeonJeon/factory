# r11 spec base fcb29f2
## Deliverables
1. SettingsView replace stub: List with sections 계정/환경/그룹/프리미엄/정보. Rows: 계정=name, 알림 Toggle(binding to UserPreferences), 테마 picker (시스템/라이트/다크 — R11 placeholder only), 그룹 관리 → GroupHubView sheet, 프리미엄 체험 → sheet w/ monetization tiers, 버전, 라이선스.
2. Shared/UserPreferences.swift @MainActor ObservableObject wrapping UserDefaults keys: reminderEnabled, themePreference, hasSeenOnboarding.
3. Shared/MemoryStore.swift @MainActor actor-safe; Codable SampleMemoryDraft struct; save/load/delete to Documents/memories.json.
4. Features/Settings/PremiumPreviewSheet.swift: shows 3 tiers from monetization strategy (무료/프리미엄 월/프리미엄 연) w/ "출시 예정" CTA.
5. UnfadingLocalized.Settings extended: account/notification/theme/premium/version/licenses + monetization copy.
6. Tests: UserPreferencesTests + MemoryStoreTests + SettingsSanityTests (≥ 5 new)
