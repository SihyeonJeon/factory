---
round: round_navigation_r1
stage: overall_planning
status: decided
participants: [claude_code, codex]
decision_id: 20260423-round3-navigation
contract_hash: none
created_at: 2026-04-23T01:10:00Z
codex_session_id: 019db43d-746e-73b3-b33c-5dda3770df91
---

# Meeting — R3 Plan: `round_navigation_r1`

## Context

- R2 `round_foundation_reset_r1` closed (2a0dc7a). Theme/Localized foundations live.
- Deepsight prototype shows 8 screens (지도/클러스터선택/핀선택/추억상세/추억만들기/달력/리와인드/그룹허브). Not all are tabs.
- Current: 3 tabs (Map/Rewind/Groups). Insufficient for deepsight surfaces.
- Per slicing manifest: navigation comes before individual screen redesigns.

## Proposal

**5-tab root + Group Hub demoted to Map overlay:**

| Order | Korean label | stage_id analogue | Target |
|---:|---|---|---|
| 1 | 지도 | map | MemoryMapHomeView |
| 2 | 캘린더 | calendar | CalendarView (stub this round) |
| 3 | 추억 | compose | presents MemoryComposerSheet as fullScreenCover |
| 4 | 리와인드 | rewind | RewindFeedView |
| 5 | 설정 | settings | SettingsView (stub this round) |

**Removed:** Groups tab. Group management reachable via top-left group chip on Map (future round implements the chip + sheet).

**Scope:**
- Rewrite `RootTabView.swift` to 5-tab
- Add stub `CalendarView.swift` and `SettingsView.swift` under `Features/`
- Compose tab intercepts selection → shows composer fullScreenCover → restores previous tab on dismiss
- `UnfadingLocalized.Tab` extended (compose/calendar/settings)
- `UnfadingLocalized.Placeholder` for stub screens
- Tests: 5 tabs exist, Korean labels correct, compose-tab-selection behavior (pattern test)
- Preserve: all existing R2 Swift modules untouched; existing feature views untouched

## Non-goals
- Actual Calendar month grid (R8)
- Actual Settings feature (R11)
- Group chip + sheet (R10)
- Composer redesign (R6)

## Challenge Section

### Risk
"Compose tab" is unusual iOS pattern; default SwiftUI TabView doesn't support "tap tab → present sheet → restore previous". Need custom `selection` Binding logic. Risk: behavior subtlety, accessibility considerations.

### Rejected alternative
Center FAB instead of a 5th tab. Rejected because deepsight's design shows a tab-like composing entrypoint in several screens; FAB overlap with map controls creates visual noise. Choose tab for consistency with deepsight intent.

### Objection
Groups tab removal is a functional downgrade if Group Hub isn't reachable. Mitigation: R10 implements the Map top-left group chip → Group Hub sheet. Interim: Settings stub gets a TODO-labeled "그룹 관리" row that routes to GroupHubView.

### Uncertainty
Whether CalendarView stub should include a `Text(상태/Coming soon)` placeholder or be entirely blank. Choose: visible Korean placeholder "달력 화면 준비 중" for honesty and for tests to grep.

## Decision

PROCEED with 5-tab structure, compose-tab-as-sheet pattern, stub CalendarView + SettingsView, Settings includes temporary "그룹 관리" row routing to GroupHubView.

## Amendment Detail

N/A — planning meeting.
