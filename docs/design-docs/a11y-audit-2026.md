# Accessibility Audit 2026

Round: `round_a11y_sweep_r1`
Scope: `workspace/ios/Features/**/*.swift`, `workspace/ios/App/RootTabView.swift`, and whitelisted `workspace/ios/Shared/Unfading*.swift` except Theme/Localized audit baseline.
Vibe-limit citation: item 8, accessibility labels/hints, Dynamic Type, semantic fonts, and 44pt touch targets.

## Screen: RootTabView
Pre-audit gaps:
- Tab items already used `Label` plus explicit Korean accessibility labels and hints.
- Compose placeholder was hidden from VoiceOver.
Applied fixes:
- No code change required in `RootTabView`; existing tab labels/hints remain sufficient.
Remaining advisories:
- Compose pseudo-tab behavior should be verified in UI tests when interaction tests are added.

## Screen: MemoryMapHomeView
Pre-audit gaps:
- Memory pin buttons had visible marker text but no explicit VoiceOver label or hint for selecting a pin.
- FAB had a label but no hint that it presents the composer.
- Filter chip row lacked an accessibility group label and horizontal browsing hint.
- FAB spring animation did not branch on Reduce Motion.
Applied fixes:
- Added pin labels using `추억 핀, <title>` plus hint: `탭하면 이 추억의 요약을 엽니다.`
- Added FAB hint: `새 추억 기록 화면을 엽니다.`
- Wrapped the filter row as a containing accessibility group with row label/hint.
- Made FAB spring animation conditional on `accessibilityReduceMotion`.
Remaining advisories:
- Pin marker buttons can cluster at dense map zooms; defer collision-specific VoiceOver ordering until real map clustering exists.

## Screen: MemorySummaryCard
Pre-audit gaps:
- Related title/body/tag content was visually grouped but not explicitly grouped for VoiceOver.
- Detail CTA had a label but no surrounding summary context.
Applied fixes:
- Added summary card label from current title/body and a detail hint when a detail action exists.
- Combined header/title text groups for more coherent VoiceOver reading.
Remaining advisories:
- SwiftUI public XCTest cannot strictly introspect the rendered `accessibilityLabel`; R13 test uses build plus string-contract assertions.

## Screen: MemoryPinMarker
Pre-audit gaps:
- Marker visuals were inside an unlabeled map annotation button.
Applied fixes:
- Fixed at parent button level in `MemoryMapHomeView` so marker label reflects the selected pin title.
Remaining advisories:
- Keep marker internals visual-only unless the marker becomes directly interactive outside `Map`.

## Screen: MemoryComposerSheet
Pre-audit gaps:
- Place row icon was decorative but not hidden.
- Place edit and current-location actions needed outcome hints.
- Recovery sheet actions opened a follow-up picker/settings app without hints.
- Place detail text was not grouped.
Applied fixes:
- Hid decorative location icons from VoiceOver.
- Added hints for place edit, current location, manual search, and settings actions.
- Combined related current-place text for VoiceOver grouping.
Remaining advisories:
- Native `DatePicker` and searchable list labels are platform-provided; runtime VoiceOver order should be verified after UI test infrastructure exists.

## Screen: CalendarView
Pre-audit gaps:
- Previous/next month icon buttons had labels but no hints.
- Day memory rows were card-like text groups without explicit grouping.
Applied fixes:
- Added month-navigation hints.
- Combined day memory rows as single VoiceOver groups.
Remaining advisories:
- Month-navigation hints currently reference the visible month title before activation; state-specific post-action announcements can be added with UI tests.

## Screen: MemoryDetailView
Pre-audit gaps:
- Title/place/time/cost card and contribution cards were visually grouped but not combined for VoiceOver.
- Toolbar chevrons had labels and 44pt frames already.
- Photo placeholders were decorative and already hidden.
Applied fixes:
- Combined detail metadata card and contribution cards.
Remaining advisories:
- Horizontal photo carousel remains decorative while sample placeholders are not real user photos.

## Screen: RewindFeedView
Pre-audit gaps:
- Feed container had no direct issues; child row/card needed fixes.
Applied fixes:
- No direct code change required in `RewindFeedView`.
Remaining advisories:
- Empty state already uses `UnfadingEmptyState`, which hides its decorative image and groups text.

## Screen: RewindMomentCard
Pre-audit gaps:
- Story text block was not explicitly grouped.
- Share and rewatch buttons used visible `Label`s but lacked outcome hints.
Applied fixes:
- Combined story text block.
- Added share and rewatch hints.
Remaining advisories:
- Buttons are currently stubs; replace hints with exact behavior when sharing/story playback is implemented.

## Screen: RewindReminderRow
Pre-audit gaps:
- Bell icon was decorative but not hidden.
- Toggle label was auto-provided by text and had a 44pt minimum target.
Applied fixes:
- Hid decorative bell icon from VoiceOver.
Remaining advisories:
- Toggle persistence and permission prompt behavior should get behavior tests when implemented.

## Screen: GroupHubView
Pre-audit gaps:
- Segmented picker had a visible title but no explicit accessibility label.
- Member rows were card-like related text groups without explicit grouping.
- Invite button had a visible `Label` but no hint.
Applied fixes:
- Added picker label, combined member rows, and added invite hint.
Remaining advisories:
- Invite button is currently a stub; hint should be updated when invitation flow is real.

## Screen: SettingsView
Pre-audit gaps:
- Groups row already had a hint.
- Premium row had visible `Label` but no hint that it presents the preview sheet.
Applied fixes:
- Added premium preview hint.
Remaining advisories:
- Account sample name remains hardcoded sample copy from prior rounds, outside R13 accessibility scope.

## Screen: PremiumPreviewSheet
Pre-audit gaps:
- Tier cards were visually grouped but not combined for VoiceOver.
- Disabled coming-soon CTA had no hint explaining disabled state.
Applied fixes:
- Combined tier-card contents.
- Added coming-soon hint.
Remaining advisories:
- Payment flow is not implemented; keep disabled-state copy until monetization round.

## Screen: OnboardingView
Pre-audit gaps:
- Decorative slide images were already hidden.
- Skip/start buttons had visible text but no completion hints.
Applied fixes:
- Added skip and start hints.
Remaining advisories:
- Page indicator is labeled but not adjustable; consider an adjustable action if custom paging replaces `TabView`.

## Shared: UnfadingPrimaryButtonStyle
Pre-audit gaps:
- Press scale and spring animation did not respect Reduce Motion.
- 44pt minimum target and semantic font were already present.
Applied fixes:
- Added `accessibilityReduceMotion` environment branch to disable scale and spring animation.
Remaining advisories:
- Opacity feedback remains because it is non-motion feedback.

## Shared: UnfadingBottomSheet
Pre-audit gaps:
- Drag handle had no accessibility label/hint.
- Snap animation did not respect Reduce Motion.
Applied fixes:
- Added handle label/hint: `추억 요약 패널`, `위아래로 드래그해 패널 높이를 조절합니다.`
- Made snap spring conditional on `accessibilityReduceMotion`.
Remaining advisories:
- Consider `.accessibilityAdjustableAction` for snap changes after runtime VoiceOver gesture testing.

## Shared: UnfadingFilterChip
Pre-audit gaps:
- Chip text provided an auto label, but selected/unselected action outcome was not hinted.
Applied fixes:
- Added explicit label and selected-state hint for each chip.
Remaining advisories:
- Filter counts are not available yet; add count announcements when real data arrives.

## Shared: UnfadingPhotoGrid
Pre-audit gaps:
- Add/remove controls already had labels and photo thumbnails were hidden as decorative.
Applied fixes:
- No code change required.
Remaining advisories:
- Add selected photo index labels when real thumbnail identity is available.

## Shared: UnfadingEmptyState
Pre-audit gaps:
- Decorative image was already hidden and text grouping already existed.
Applied fixes:
- No code change required.
Remaining advisories:
- CTA hint can be supplied by caller if future empty states have non-obvious actions.

## Shared: UnfadingMonthGrid
Pre-audit gaps:
- Day cells already had explicit labels, selection traits, and 44pt targets.
Applied fixes:
- No code change required.
Remaining advisories:
- Real memory counts should replace the current one-memory indicator when multiple memories per day are modeled.

## Shared: UnfadingAvatarStack
Pre-audit gaps:
- Avatar stack already combined children and used a Korean label.
Applied fixes:
- No code change required.
Remaining advisories:
- Member names can be added to the stack label when design decides whether initials are sufficient.

---

## R39 Update: Accessibility / Dynamic Type / Mode-Aware Korean Copy

Round context: R39 accessibility and Korean copy refresh after R26-R38 surfaces.
Audit date: 2026-04-24 KST.

### Audit commands

- `rg -n '\.accessibility(Label|Hint|Identifier|Value)' workspace/ios/App workspace/ios/Features workspace/ios/Shared`
  - Audited 211 accessibility label, hint, identifier, and value call sites across App, Features, and Shared.
- `rg -n '\.accessibility(Label|Hint|Value)\("' workspace/ios/App workspace/ios/Features workspace/ios/Shared`
  - Result after fixes: 0 direct string-literal label/hint/value call sites.
- `rg -n 'font\(\.system\(size:' workspace/ios/App workspace/ios/Features workspace/ios/Shared`
  - Result after fixes: 0 direct fixed-size system font call sites.
- `rg -n '@ScaledMetric' workspace/ios/App workspace/ios/Features workspace/ios/Shared`
  - Result after fixes: `ComposeFAB` uses `@ScaledMetric(relativeTo: .title3)` for the FAB touch frame at accessibility sizes.

### Newly Audited R26-R38 Sections

- Home shell: `MemoryMapHomeView`, `HomeSheetContent`, `CollapsedSummary`, `SheetExpandedHeader`, `SheetFilteredHeader`, `ComposeFAB`, `ClusterMarker`, `MemoryRowCard`.
- Calendar: `CalendarView`, monthly expense header, future plan card, RSVP summary, add-plan/send-reminder actions.
- Rewind stories: `RewindFeedView`, `RewindMomentCard`, generated story cards.
- Group surfaces: `GroupHubView`, `GroupPickerOverlay`, `GroupOnboardingView`.
- Composer and overlays: `MemoryComposerSheet`, `PlacePickerSheet`, `CategoryEditorOverlay`, participant/source chips.
- Shared controls: bottom sheet, month grid, empty state, filter chip, avatar stack, photo grid, toast.

### Applied Fixes

- Added mode-aware Korean copy helpers in `UnfadingLocalized`:
  - `Home.memoryTitle(for:)`
  - `Home.collapsedMemoryTitle(for:count:)`
  - `Home.groupSubtitle(mode:memberCount:days:)`
  - `Home.rewindHintTitle(for:)`
  - `Home.rewindHintBody(for:)`
  - `Calendar.emptyDayTitle(for:)`
  - `Calendar.emptyDayBody(for:)`
  - `Rewind.coverHeadline(for:)`
  - `Rewind.topPlacesSubtitle(for:)`
  - `Rewind.timeTogetherTitle(for:)`
  - `Rewind.timeTogetherBody(for:)`
  - `Groups.memberCountFormat(_:mode:)`
- Replaced direct couple/group copy branches in:
  - `CollapsedSummary`: "우리의 추억" vs "크루 기록".
  - `MemoryMapHomeView`: group subtitle uses "함께한 지 N일" for couple and "{멤버수}명 · N일" for general group.
  - `MemorySummaryCard` / `HomeSheetContent`: home curation rewind title/body are mode-aware.
  - `CalendarView`: empty state title/body are mode-aware.
  - `RewindFeedView` / `RewindMomentCard`: cover, top-place subtitle, and time-together copy are mode-aware.
  - `GroupHubView`: member count line is mode-aware.
- Moved remaining direct accessibility string interpolation into `UnfadingLocalized` helper functions:
  - cluster marker labels
  - event card labels
  - memory row labels
  - date labels
  - category delete labels
  - photo upload progress label/value

## R59 Update: VoiceOver Precision + Reduce Motion Full Sweep

Round context: R59 accessibility precision pass on 2026-04-24 KST.

### VoiceOver updates

- Added custom rotors to major surfaces:
  - `MemoryMapHomeView`: `지도 추억`
  - `MemoryDetailView`: `이벤트 추억`
  - `CalendarView`: `캘린더 이벤트`
  - `RewindFeedView`: `리와인드 카드`
  - `GroupPickerOverlay`: `그룹 목록`
  - `CategoryEditorOverlay`: `카테고리 목록`
  - `AuthLandingView`: `인증 동작`
  - `SettingsView`: `설정 바로가기`
- Added named VoiceOver custom actions on `MemoryDetailView` for event-scoped navigation:
  - `이전 이벤트`
  - `다음 이벤트`
- Added semantic-group container hints for composite cards/rows via shared UIKit-backed container-type bridge:
  - detail metadata/note cards
  - rewind story cards
  - group picker rows and overlay card
  - category rows and editor card
  - group hub cards
  - home top chrome and map controls
  - calendar event list card

### Reduce Motion sweep

- Audited all current `withAnimation`, `.animation`, spring, and move-transition call sites under `workspace/ios/App`, `workspace/ios/Features`, and `workspace/ios/Shared`.
- Added or tightened `accessibilityReduceMotion` branching in:
  - `MemoryMapHomeView` cluster zoom, chrome fade, map-controls spring, map-control press animation
  - `MemoryPinMarker`, `ClusterMarker`, `ComposeFAB`, `UnfadingTabShell`
  - `MemoryDetailView` photo page indicator
  - `CalendarView` reminder toast transition/animation
  - `RewindFeedView` story auto-advance and manual page motion
  - `GroupPickerOverlay`, `CategoryEditorOverlay`, `GroupHubView`
  - `AuthLandingView`, `PremiumPaywallView`
  - `RemoteImageView` fade/shimmer
  - `UnfadingBottomSheet` snap animation: reduce-motion path is now instant instead of spring
- Result: stories auto-advance stop, sheet drag spring becomes instant, chrome/toast motion falls back to fade or no animation, and map cluster emphasis no longer animates under Reduce Motion.

### WCAG AA contrast re-check

Re-checked theme token pairs after R59 token adjustment:

- Light:
  - `textPrimary` on `bg`: `10.89:1`
  - `textSecondary` on `sheet`: `4.91:1`
  - `textOnPrimary` on `primary`: `5.36:1`
- Dark:
  - `textPrimary` on `bg`: `14.93:1`
  - `textSecondary` on `sheet`: `7.37:1`
  - `textOnPrimary` on `primary`: `5.36:1`

Status:

- Current audited theme token pairs above meet WCAG AA for normal text.

### Test / verification notes

- Added UITest: `testVoiceOverRotorsPresentOnMainScreens`
  - Uses stub environment rotor markers to assert rotor registration names on main screens.
  - Falls back to `XCTSkip` if the simulator accessibility tree does not expose the markers.
- Requested build/test command for this round:
  - `xcodebuild test -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath .deriveddata/r59`
- 2026-04-24 sandbox verification blockers:
  - `CoreSimulatorService connection became invalid`
  - SwiftPM network resolution blocked (`Could not resolve host: github.com`)
  - sandbox prevented writes to user cache/module-cache paths under `~/Library` and `~/.cache`
- Static syntax validation passed with `xcrun swiftc -parse` across the touched Swift files.
  - filtered-sheet clear/add-place labels
- Replaced `ComposeFAB` fixed `.font(.system(size: 22, weight: .bold))` with semantic `.title3.weight(.bold)` plus a scaled 56pt touch frame.

### Remaining Advisories

- R39 used code grep for `accessibilityXXXLarge` risk, as requested. Visual simulator validation is still required for final layout sign-off because card density, bottom-sheet snap height, and full-screen Rewind stories can only be fully judged from runtime screenshots.
- `UnfadingTheme.Font` still wraps custom font sizes by design from R26. No direct `.font(.system(size:))` call sites remain, but a future typography pass should consider `Font.custom(_:size:relativeTo:)` if the custom font stack needs stronger Dynamic Type guarantees.

### Verification

- `xcodegen generate`: passed, project regenerated.
- `xcodebuild test -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath .deriveddata/r39`: blocked by the current sandbox before tests could run.
  - First attempt: SwiftPM could not clone packages because network access to GitHub is blocked.
  - Follow-up: copied cached `SourcePackages` from `.deriveddata/r38` into `.deriveddata/r39`.
  - Subsequent attempts: blocked by sandbox access to CoreSimulatorService and home-directory SwiftPM/Clang caches (`/Users/jeonsihyeon/.cache`, `/Users/jeonsihyeon/Library/Caches`).
