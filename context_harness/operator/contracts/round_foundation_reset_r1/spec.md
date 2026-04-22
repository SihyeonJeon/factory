# round_foundation_reset_r1 Specification

## Scope

This is the first implementation foundation round after the real-state reset. It creates reusable Swift assets and refactors the current MVP-scale workspace to use them. It also reconciles active process docs so future rounds do not inherit the stale Sprint 51 / 140-test narrative.

Base commit for this round: `44e2a1d`.

## Source Inventory

### Deepsight Inputs

| Source | SHA-256 |
|---|---|
| `docs/design-docs/unfading_design/Unfading Prototype.html` | `sha256:df8fe6badd57d17805a36385c1d9f62efd4d964efca3aa7bdc8d9c2189cb471e` |
| `docs/design-docs/unfading_design/check.png` | `sha256:cb14f4bb14080f84d8c1b8ef4cce095505f778548ab998a6514038da7242e614` |
| `docs/design-docs/unfading_design/debug.png` | `sha256:0bfe72e4668458114180ea91d60ae019c99e46994ea7326ba7ae33c855947d92` |
| `docs/design-docs/deepsight_tokens.md` | `sha256:638425b8c8aa5cbcf0826fc31980b31a8b5ebc0dd9ed6c669c03c6c7c9d9a59f` |

The `unfading_design/` files are SHA-identical to the Round 1 `travel_deepsight/` inputs.

### Pre-Round Swift Targets

| Source | SHA-256 |
|---|---|
| `workspace/ios/App/RootTabView.swift` | `sha256:8c2372c6c2a070505e0ed06553a2a13bdb13265d90a840ad90716106b4bc2acd` |
| `workspace/ios/Features/Home/MemoryMapHomeView.swift` | `sha256:07e59fc7139d7ad55a76fbcca0bab6cf0e2d5627b2f7d16791c991d40cee8bfc` |
| `workspace/ios/Features/Home/MemoryComposerSheet.swift` | `sha256:9a6c67600bb6a28ef65037a30f1558bcef295656cc8d4831eebf1a7ae466b749` |
| `workspace/ios/Features/Home/MemorySummaryCard.swift` | `sha256:216742219d750d161ba213c14774ef5b825c4a88405d30260d332865096990f2` |
| `workspace/ios/Features/Home/MemoryPinMarker.swift` | `sha256:cdc5675c1bd0261c097b633c1c0782d56aa92ccd040f7a0a8701ded49da45a26` |
| `workspace/ios/Features/Rewind/RewindFeedView.swift` | `sha256:9e298584a43fc9d2cee45f06d6eada449ab9ba5e7572ec1179e529e09c51205d` |
| `workspace/ios/Features/Groups/GroupHubView.swift` | `sha256:4ce74e2126681b27c3c00d3f8d126f9e88a2917a91a873943f6595699d8bb48c` |
| `workspace/ios/Tests/MemoryMapTests.swift` | `sha256:8b9d883ec179513af272fe4b41de81620e024b0935b413a9878e349a2b4dc4b5` |

## Reusable Modules

### `workspace/ios/Shared/UnfadingTheme.swift`

Canonical namespace for reusable design tokens.

Required API shape:

```swift
enum UnfadingTheme {
    enum Color { ... }
    enum Font { ... }
    enum Radius { ... }
    enum Spacing { ... }
    enum Sheet { ... }
}
```

Required members:

- `UnfadingTheme.Color.coral` = `#F5998C`
- `UnfadingTheme.Color.primary` aliases or maps to coral
- `UnfadingTheme.Color.lavender` = `#C2B0DE`
- `UnfadingTheme.Color.cream` = `#FFFAF5`
- `UnfadingTheme.Color.sheet` = `#FFF8F0`
- `UnfadingTheme.Color.surface` = `#FAF2EB`
- `UnfadingTheme.Color.textPrimary` = `#403833`
- `UnfadingTheme.Color.textSecondary` = `#8C8078`
- `UnfadingTheme.Color.textTertiary` = `#B5A89E`
- `UnfadingTheme.Color.textOnPrimary` for white-on-coral text
- `UnfadingTheme.Color.textOnOverlay` for overlay text formerly using inline white
- `UnfadingTheme.Color.primarySoft` for `rgba(245,153,140,0.15)`-style accents
- `UnfadingTheme.Radius.card = 20`
- `UnfadingTheme.Radius.button = 16`
- `UnfadingTheme.Radius.chip = 12`
- `UnfadingTheme.Radius.compact = 8`
- `UnfadingTheme.Sheet.collapsed = 0.22`
- `UnfadingTheme.Sheet.default = 0.52`
- `UnfadingTheme.Sheet.expanded = 0.88`

Replaces:

- `Color.accentColor`
- `Color.white.opacity(...)`
- future inline `Color(red:...)` declarations outside the theme file
- magic radius values where this round touches a reusable surface

### `workspace/ios/Shared/UnfadingLocalized.swift`

Plain Swift namespace for Korean user-facing strings in the current app surface.

Required API shape:

```swift
enum UnfadingLocalized {
    enum Tab { ... }
    enum Accessibility { ... }
    enum Home { ... }
    enum Composer { ... }
    enum Summary { ... }
}
```

Current English-to-Korean inventory for this round:

| Current literal | Replacement key | First Korean value |
|---|---|---|
| `Map` | `UnfadingLocalized.Tab.map` | `지도` |
| `Map tab` | `UnfadingLocalized.Accessibility.mapTabLabel` | `지도 탭` |
| `Browse memory pins and place history on the map.` | `UnfadingLocalized.Accessibility.mapTabHint` | `지도에서 추억 핀과 장소 기록을 둘러봅니다.` |
| `Rewind` | `UnfadingLocalized.Tab.rewind` | `리와인드` |
| `Rewind tab` | `UnfadingLocalized.Accessibility.rewindTabLabel` | `리와인드 탭` |
| `Review rewind moments and reminder settings.` | `UnfadingLocalized.Accessibility.rewindTabHint` | `리와인드 순간과 알림 설정을 확인합니다.` |
| `Groups` | `UnfadingLocalized.Tab.groups` | `그룹` |
| `Groups tab` | `UnfadingLocalized.Accessibility.groupsTabLabel` | `그룹 탭` |
| `Create groups, join groups, and manage invites.` | `UnfadingLocalized.Accessibility.groupsTabHint` | `그룹을 만들고 초대와 참여를 관리합니다.` |
| `Show current location` | `UnfadingLocalized.Accessibility.showCurrentLocationLabel` | `현재 위치 보기` |
| `Centers the map on your current location when permission is available.` | `UnfadingLocalized.Accessibility.showCurrentLocationHint` | `위치 권한이 있을 때 지도를 현재 위치로 이동합니다.` |
| `New Memory` | `UnfadingLocalized.Home.newMemory` | `새 추억` |
| `Add memory` | `UnfadingLocalized.Accessibility.addMemoryLabel` | `추억 추가` |
| `Tonight's rewind` | `UnfadingLocalized.Summary.tonightsRewind` | `오늘의 리와인드` |
| `Sangsu rooftop dinner` | `UnfadingLocalized.Summary.sampleTitle` | `상수 루프톱 저녁` |
| `Three years ago today, your group dropped a pin here after the concert. Two new reactions arrived this morning.` | `UnfadingLocalized.Summary.sampleBody` | `3년 전 오늘, 이곳에서 공연 뒤 함께 핀을 남겼습니다. 오늘 아침 새 반응 2개가 도착했습니다.` |
| `4 friends` | `UnfadingLocalized.Summary.friendCount` | `친구 4명` |
| `Joy` | `UnfadingLocalized.Summary.joyTag` | `기쁨` |
| `Night out` | `UnfadingLocalized.Summary.nightOutTag` | `밤 나들이` |
| `Photo set` | `UnfadingLocalized.Summary.photoSetTag` | `사진 모음` |
| `Today, 8:40 PM` | `UnfadingLocalized.Composer.sampleTime` | `오늘 오후 8:40` |
| `Add from Library` | `UnfadingLocalized.Composer.addFromLibrary` | `보관함에서 추가` |
| `Your first photo can prefill time and place when metadata is available.` | `UnfadingLocalized.Composer.metadataHint` | `첫 사진의 메타데이터로 시간과 장소를 미리 채울 수 있습니다.` |
| `Choose Place Manually` | `UnfadingLocalized.Composer.choosePlaceManually` | `장소 직접 선택` |
| `Use Current Location` | `UnfadingLocalized.Composer.useCurrentLocation` | `현재 위치 사용` |
| `Location Access Off` | `UnfadingLocalized.Composer.locationAccessOff` | `위치 접근 꺼짐` |
| `You can still save this memory by choosing a place manually, or re-enable location access in Settings for current-location autofill.` | `UnfadingLocalized.Composer.locationRecoveryHint` | `장소를 직접 선택하면 이 추억을 저장할 수 있습니다. 현재 위치 자동 입력을 사용하려면 설정에서 위치 접근을 다시 켜세요.` |
| `Current place` | `UnfadingLocalized.Composer.currentPlace` | `현재 장소` |

Revision of Korean wording is allowed during implementation if noted in evidence.

### `workspace/ios/Shared/UnfadingButtonStyle.swift`

Reusable primary button press style.

Required API shape:

```swift
struct UnfadingPrimaryButtonStyle: ButtonStyle { ... }
extension ButtonStyle where Self == UnfadingPrimaryButtonStyle { ... }
```

Required behavior:

- Coral fill from `UnfadingTheme.Color.primary`
- Text/icon foreground from `UnfadingTheme.Color.textOnPrimary`
- Button radius from `UnfadingTheme.Radius.button`
- Minimum height 44 where the style is applied to tappable controls
- Press feedback through scale and/or opacity without breaking Dynamic Type

Replaces:

- one-off coral/accent button styling in touched views
- future repeated primary button declarations

### `workspace/ios/Shared/UnfadingCardBackground.swift`

Reusable card surface modifier.

Required API shape:

```swift
struct UnfadingCardBackground: ViewModifier { ... }
extension View {
    func unfadingCardBackground(...) -> some View
}
```

Required behavior:

- Cream/warm surface from `UnfadingTheme.Color.card` or `.sheet`
- Radius from `UnfadingTheme.Radius.card`
- Subtle shadow or material-compatible fallback
- No inline colors outside the theme file

Replaces:

- repeated `RoundedRectangle(cornerRadius: ...)` card backgrounds in touched views
- inline `Color.white.opacity(...)` card/badge backgrounds

## Refactor Targets

Refactor source files using pattern targets rather than hardcoded line numbers. Line numbers may drift during implementation.

| File | Required replacements |
|---|---|
| `workspace/ios/App/RootTabView.swift` | Replace English tab labels and accessibility strings with `UnfadingLocalized`; replace `.tint(Color.accentColor)` with `UnfadingTheme.Color.primary`. |
| `workspace/ios/Features/Home/MemoryMapHomeView.swift` | Replace English accessibility strings and `New Memory` / `Add memory` with `UnfadingLocalized`; apply `UnfadingPrimaryButtonStyle` where appropriate. |
| `workspace/ios/Features/Home/MemoryComposerSheet.swift` | Replace English text/labels/accessibility strings listed above with `UnfadingLocalized`; replace `Color.accentColor` with `UnfadingTheme.Color.primary` or semantic token. |
| `workspace/ios/Features/Home/MemorySummaryCard.swift` | Replace English text/tag labels with `UnfadingLocalized`; replace `Color.white.opacity(...)` with `UnfadingTheme.Color` token; replace `Color.accentColor` with theme token; use `UnfadingCardBackground` where suitable. |
| `workspace/ios/Features/Home/MemoryPinMarker.swift` | Review inline color usage and migrate touched marker styling to `UnfadingTheme.Color` where applicable. |
| `workspace/ios/Features/Rewind/RewindFeedView.swift` | Import/use shared module if needed for module proof or localized visible strings. |
| `workspace/ios/Features/Groups/GroupHubView.swift` | Import/use shared module if needed for module proof or localized visible strings. |

## Tests

Add `workspace/ios/Tests/UnfadingThemeTests.swift`.

Required test coverage:

- `UnfadingTheme.Color.coral` resolves to `#F5998C` or an equivalent stable hex helper result.
- `UnfadingTheme.Radius` covers `20`, `16`, `12`, `8`.
- `UnfadingTheme.Sheet` covers `0.22`, `0.52`, `0.88`.
- Representative `UnfadingLocalized` values are non-empty and Korean.
- `UnfadingPrimaryButtonStyle` and `UnfadingCardBackground` are referenced by test code so reusable modules are not nominal-only.

The total test count must increase from 10 to at least 18.

## Doc Reconciliation

Required docs:

- `context_harness/SESSION_RESUME.md` must contain a truthful current-state section: 12 Swift files, 10 tests baseline, 3 tabs, no pre-round `UnfadingTheme`, no pre-round Korean UI.
- Active `SESSION_RESUME.md` must not present the Sprint 51 / 140-test narrative as current truth.
- `docs/exec-plans/sprint-history-pre-v5.md` must exist and label the older narrative as pre-v5/unverified archive.
- `docs/references/coding-conventions.md` must note that `UnfadingTheme` enforcement begins with this foundation reset round.
- `SKILLS.md` S-17 must clarify that its checklist is forward-looking for post-reset work and that pre-round-2 code did not comply.

## Git Tracking Decision

This round should make Swift source traceable without committing generated build products.

Update `.gitignore` so these are tracked:

- `workspace/ios/App/**`
- `workspace/ios/Features/**`
- `workspace/ios/Shared/**`
- `workspace/ios/Tests/**`
- `workspace/ios/project.yml`

Keep generated Xcode/build outputs ignored, including `workspace/ios/*.xcodeproj`, DerivedData, and build products.

## Non-Goals

- No Calendar, Settings, Memory Detail, archive, or new screen implementation.
- No root navigation redesign beyond Korean labels/theme tint.
- No Deepsight map redesign beyond theme token setup and small touched-file token replacements.
- No full `Localizable.xcstrings` migration.
- No full Swift linter framework beyond grep-based acceptance checks.
- No broad feature refactor outside the listed source targets.
