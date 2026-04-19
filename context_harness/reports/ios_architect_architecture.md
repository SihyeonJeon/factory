I'm blocked: the plan workflow expects me to write the contract to `/Users/jeonsihyeon/.claude/plans/synthetic-snacking-muffin.md`, but neither `Write` nor `Edit` is available in this session (not in top-level tools, not discoverable via `ToolSearch`). I cannot create the plan file.

Since the architecture contract is ready and you're resuming a live delivery cycle, here it is inline. If you want it persisted, enable `Write`/`Edit` and I'll move it into the plan file.

---

# iOS Architecture Contract — Cycle M5 → M10 (Unfading)

## Context
Resuming from the 2026-04-08 baseline. M1–M4 landed across UI + logic worktrees (place-confirmation gating, marker↔sheet sync, cluster zoom, filter-change pin animation). Current cycle closes with an M5 merge + dual-auditor gate; next cycle covers the three unimplemented P0 epics: Epic 1 (Group creation + invite), Epic 2 remaining (memory record with photos + 6 emotion tags), Epic 4 (Rewind reminders).

The critical gap: the canonical hierarchy `Group → DateEvent → Memory → MemoryPost` (non-negotiable per `ui_ux_screen_contract.md:29`) **does not yet exist in code**. Only transient `SampleMemoryPin` + `MemoryDraftTag` (4 samples, spec needs 6) + a `Group` struct with no `mode` field exist. This blocks M6, M8, M9 until an architecture contract lands.

## Canonical workspace decision
Per `native_ios_strategy.md`, merge target is `/Users/jeonsihyeon/factory/workspace/ios/MemoryMap.xcodeproj` (XcodeGen, iOS 18, Swift 5.10, MapKit, bundle `com.jeonsihyeon.memorymap`). Worktrees `.worktrees/ios_ui_builder-delivery/` and `.worktrees/ios_logic_builder-delivery/` are integration lanes only — code must land in the canonical workspace at each QA gate. Evaluation evidence must come from `xcodebuild`, not Expo.

## Domain model (new `Shared/DomainModels.swift`, logic lane)
Additive pre-M6 enabler, rides in the M5 merge:

- `enum GroupMode: String, Codable { case couple, generalGroup }` — required by Epic 1 AC and screen contract.
- `struct DateEvent { id, groupID, title, startDate, endDate?, summary?, isMultiDay }` — single-day default, explicit multi-day promotion only.
- `struct Memory { id, eventID, placeID, coordinate, representativeTimestamp, emotionTagIDs: [String] }`.
- `struct MemoryPost { id, memoryID, authorID, photos: [PhotoRef], note, createdAt }` — multi-contributor (screen contract §186-199).
- `struct PhotoRef { id, localAssetIdentifier?, fileURL?, capturedAt?, coordinate? }` — abstracts PHAsset vs file.
- `enum EmotionTag: String, CaseIterable` — **exactly 6 cases** (joy, calm, grateful, nostalgic, excited, bittersweet) per `sprint_contract.json` Epic 2 AC. `MemoryDraftTag` becomes a view adapter.

Extend `workspace/ios/Shared/Support/GroupModels.swift`: add `var mode: GroupMode` on `Group`. Extend `GroupStore.createGroup` at `GroupStore.swift:68` to accept and persist `mode`.

## File ownership & lane boundaries

| Area | Lane | Path under `workspace/ios/` |
|---|---|---|
| Domain models | logic | `Shared/DomainModels.swift` (new) |
| GroupStore, MemoryStore (new), MemoryMapStore, DraftStore | logic | `Shared/` + `Features/<feature>/` |
| `InvitationService`, `NotificationScheduler`, `RewindQuery` (new) | logic | `Shared/Services/` (new folder) |
| Group creation + mode picker UI | UI | `Features/Groups/Views/GroupCreationView.swift` + new `GroupModePicker.swift` |
| Invite share + join UI | UI | `InvitationShareView.swift` (exists) + new `JoinGroupView.swift` |
| Memory composer photo grid + chips | UI | `Features/Home/MemoryComposerSheet.swift` (extend) |
| Rewind card + share | UI | `Features/Rewind/RewindMomentCard.swift` (extend) |

**Boundary rule:** UI lane never constructs domain objects directly — only via store APIs. Files under `Shared/Services/` must not import SwiftUI so they remain unit-testable.

## State boundaries
- `GroupStore` (`@MainActor`) keeps list + mode + pending invitation, but delegates invite-code generation to `InvitationService` (extracted — currently inline at `GroupStore.swift:145`).
- `InvitationService` (new, plain actor): code generation, 24 h expiry, reissue, join validation. No `@Published`.
- `MemoryStore` (new, `@MainActor`): owns the DateEvent/Memory/MemoryPost graph scoped by active group. Enforces the 10-photo ceiling and 6-tag domain.
- `MemoryComposerDraftStore` (existing): extend with `photoDraftRefs` + `selectedTagIDs`; returns a `MemoryDraft` value on submit — it **never** mutates `MemoryStore` directly.
- `MemoryMapStore` (existing): stays authoritative for `selectionRevision`; re-read pins from `MemoryStore` instead of `SampleMemoryPin.samples`.
- `NotificationScheduler` (new): wraps `UNUserNotificationCenter`. Radius 100–500 m, default 200 m per Epic 4 AC.
- `RewindQuery` (new): pure query producing `[RewindMoment]` for N-years-ago today.

## HIG non-negotiables (M6–M9)
- 44 pt hit targets: mode segments, tag chips, photo delete buttons, share button, invite copy, radius slider thumb.
- `.safeAreaInset`/`NavigationStack` only — no hard-coded insets.
- Dynamic Type: `.body`-family; composer note uses `TextField(..., axis: .vertical).lineLimit(1...10)`.
- Dark mode previews on every new screen.
- VoiceOver labels on every control; photo grid uses `.accessibilityElement(children: .contain)` with parent label "Photo attachments, N of 10".
- `@Environment(\.accessibilityReduceMotion)` — reuse the cluster-zoom pattern on new composer/rewind animations.
- **M1 place-confirmation gate must not regress in M8** (explicit regression risk in `planning_report.feedback_loop`).
- `Info.plist` location/photo/notification strings already present — verify, don't duplicate.

## Dependency policy
Zero third-party adds for M6–M9. Use `PhotosPicker` (PhotosUI), `ShareLink` (iOS 16+), `UNUserNotificationCenter` direct. The existing `Shared/Components/ImagePicker.swift` and `ShareSheet.swift` UIKit wrappers should be removed if `PhotosPicker`/`ShareLink` cover the use cases — no backwards-compat stubs.

## Critical files to modify

**New:**
- `Shared/DomainModels.swift`
- `Shared/MemoryStore.swift`
- `Shared/Services/InvitationService.swift`
- `Shared/Services/NotificationScheduler.swift`
- `Shared/Services/RewindQuery.swift`
- `Features/Groups/Views/JoinGroupView.swift`
- `Features/Groups/Views/GroupModePicker.swift`

**Modify:**
- `Shared/Support/GroupModels.swift` — add `mode`
- `Shared/Support/GroupStore.swift` — accept `mode`, delegate invites
- `Shared/SampleModels.swift` — extend to 6 emotion tags
- `Shared/MemoryComposerDraftStore.swift` — photos + tags + `MemoryDraft` output
- `Features/Home/MemoryMapStore.swift` — read from `MemoryStore`
- `Features/Groups/Views/GroupCreationView.swift` — embed mode picker
- `Features/Home/MemoryComposerSheet.swift` — photo grid, chips, note; preserve place-confirmation gate
- `Features/Rewind/RewindMomentCard.swift` — wire to `RewindQuery`, add `ShareLink`
- `workspace/ios/project.yml` + regenerated `.xcodeproj` if new folders appear

**Reuse verbatim:**
- `LocationPermissionStore.swift` for M9 location-rewind toggle
- `PlaceConfirmationRow` + `PlaceConfirmationState` for M8 gate
- `MemoryMapStore.selectionRevision` pattern

## Lane execution order
1. **M5 (now)** — merge worktrees into canonical workspace + land domain models as additive enabler. `xcodebuild -list` + simulator build. Dual-auditor APPROVE.
2. **M6** — `GroupMode` + mode picker. Seed one `.couple` group for evaluation.
3. **M7** — `InvitationService` extraction + `JoinGroupView` + `ShareLink`. Expired-code recoverable error state.
4. **M8** — `MemoryStore` + composer photo/tag extension. **Blocked on M6.** Place-confirmation regression check mandatory.
5. **M9** — `NotificationScheduler` + `RewindQuery` + rewind card. Logic-lane parallel with M8 allowed (disjoint files); UI stays sequential.
6. **M10** — dual-auditor sign-off against Epic 1/2/4 AC.

## Verification (runs at M5 and M10 gates)
1. `cd workspace/ios && xcodebuild -list` → `MemoryMap` scheme present.
2. `xcodebuild -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 15' build` — zero warnings.
3. `xcodebuild ... test` — extend `MemoryMapTests` with unit tests for `InvitationService` (expiry + reissue), `MemoryStore` (10-photo ceiling, tag domain), `NotificationScheduler` (mock `UNUserNotificationCenter`), `RewindQuery` (N-years-ago selection).
4. Simulator walkthrough, screenshots to `context_harness/reports/`:
   - Create couple + general_group → both in list.
   - Share invite → copy code → `JoinGroupView` accepts.
   - Force-expire invite → recoverable error state.
   - Memory composer: 10 photos OK, 11th blocked, place-gate enforced, multi-select chips, save → pin on map.
   - Rewind: seeded 1-year-ago memory renders, `ShareLink` opens without crash.
   - Location rewind: radius slider at 100/200/500 bounds, toggle off clears region.
5. HIG audit (`hig_guardian_hig_audit.md`): dark mode, Dynamic Type XL, 44 pt overlay, safe-area overlay, VoiceOver rotor walk per new screen.
6. Code audit diff vs `acceptance.md`, `sprint_contract.json`, `ui_ux_screen_contract.md`. No UI-lane domain construction; no SwiftUI imports under `Shared/Services/`.
7. Both auditors APPROVE in `context_harness/blackboard.md` before merge.

---

**Blocker:** `Write`/`Edit` tools are not available in this session, so I cannot persist this to `~/.claude/plans/synthetic-snacking-muffin.md` or call `ExitPlanMode` against a real plan file. Want me to retry once you enable file-write tools, or should I hand this off to the implementation_lead agent via the harness instead?
