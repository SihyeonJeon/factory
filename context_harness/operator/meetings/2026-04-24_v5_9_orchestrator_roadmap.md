---
round: none
stage: overall_planning
status: draft
participants: [claude_code, codex]
decision_id: 20260424-v5-9-orchestrator-roadmap
contract_hash: none
created_at: 2026-04-24T00:00:00+09:00
---

## Retrospective

60+ rounds after the prior loop, the remaining defects are not small polish gaps. They show a process failure: rounds were too broad, acceptance lists were too large, and verification did not cross-check code structure, actual Playwright/simulator/runtime behavior, and process evidence before feeding results back to planning/design/development. A 10-round/6-hour execution model is possible only when every loop has a narrow defect target, a dependency graph, and a hard close gate. v5.9 therefore flips the operating model: Codex GPT-5.5 orchestrates sharp rounds, Verifier Codex checks all 3 axes, and Claude Code assists build/git/MCP/evidence/user communication.

## Context

- User-reported defects: A1-A4, B1-B3, C1-C2, D1, E1.
- Audit files: `workspace/ios/Shared/UnfadingBottomSheet.swift`, `workspace/ios/Features/Home/MemoryMapHomeView.swift`, `workspace/ios/App/UnfadingTabShell.swift`, `workspace/ios/ShareExtension/ShareViewController.swift`, `workspace/ios/Features/Home/MemoryComposerSheet.swift`.
- Additional audit files opened for precise root cause: `workspace/ios/Shared/LocationPermissionStore.swift`, `workspace/ios/Features/Composer/PlacePickerSheet.swift`, `workspace/ios/Features/Composer/NearbyPlaceService.swift`, `workspace/ios/Features/Home/MemoryComposerState.swift`, `workspace/ios/App/ComposerLaunchRoute.swift`.
- v5.9 protocol draft: `context_harness/operator/REGULATION_v5_9.md`.

## Defect To Round Mapping

| Defect | Round ID | Priority | Audit basis |
|---|---|---:|---|
| A1 snap velocity projection 부족 | `round_sheet_velocity_projection_r1` | P0 | `UnfadingBottomSheet.swift:70-102`, `249-267` nearest-only projected fraction |
| A2 expanded true fullscreen 아님 | `round_sheet_true_fullscreen_r1` | P0 | `UnfadingBottomSheet.swift:153-157`, `216`; tabbar height deducted even when expanded |
| A3 collapsed sheet tabbar 밑 숨김 | `round_sheet_collapsed_tabbar_clearance_r1` | P0 | `UnfadingBottomSheet.swift:154-157,216`; `MemoryMapHomeView.swift:529-533` independent reserve math |
| A4 search/top chrome/filter/control overlap | `round_home_chrome_collision_r1` | P0 | `MemoryMapHomeView.swift:79-107`, `511-528` fixed y constants |
| B1 user location not visible/centered | `round_map_user_location_annotation_r1` | P0 | `MemoryMapHomeView.swift:240-275`, no user annotation; `300-306` button only calls permission store |
| B2 selected map coordinate replaced by nearby POI | `round_map_pin_selection_stability_r1` | P0 | `PlacePickerSheet.swift:124-139` returns `match.pickedPlace`; `NearbyPlaceService.swift:62-64` uses POI coordinate |
| B3 visible state monitoring insufficient | `round_home_state_indicators_r1` | P1 | `MemoryMapHomeView.swift:417-424`, `441-451` state sync has no visible indicator layer |
| C1 tabbar too large | `round_tabbar_compact_height_r1` | P0 | `UnfadingTabShell.swift:278`, `300-337` fixed 83pt height |
| C2 tabbar too high/contents obscured | `round_tabbar_content_insets_r1` | P0 | `UnfadingTabShell.swift:113-134`; sheet/top math depends on same height indirectly |
| D1 wrong button placement | `round_button_placement_audit_r1` | P1 | `MemoryMapHomeView.swift:583-593`, `669-684`, `703-713`; `UnfadingTabShell.swift:91-103` |
| E1 share temp file ignored by composer | `round_share_temp_photo_ingest_r1` | P0 | `ShareViewController.swift:103-144` returns temp path; `MemoryComposerSheet.swift:37`, `594-599` only assetIdentifier |
| Process gap | `round_verification_harness_three_axis_r1` | P0 | prior loop lacked mandatory 3-axis verifier close gate |

## Dependency DAG

```text
round_verification_harness_three_axis_r1
  -> all implementation rounds use 3-axis close gate

round_tabbar_compact_height_r1
  -> round_tabbar_content_insets_r1
  -> round_sheet_collapsed_tabbar_clearance_r1
  -> round_home_chrome_collision_r1
  -> round_button_placement_audit_r1
  -> round_home_state_indicators_r1

round_sheet_velocity_projection_r1
  -> round_sheet_true_fullscreen_r1
  -> round_sheet_collapsed_tabbar_clearance_r1

round_map_user_location_annotation_r1
  -> round_home_state_indicators_r1

round_map_pin_selection_stability_r1
  -> round_home_state_indicators_r1

round_share_temp_photo_ingest_r1
  (independent P0)
```

## Priority

| Priority | Start order | Reason |
|---|---|---|
| P0 | `round_verification_harness_three_axis_r1` | Prevents repeating the same broad-loop failure before implementation starts. |
| P0 | `round_tabbar_compact_height_r1` | Unblocks sheet clearance, bottom inset model, and chrome collision measurements. |
| P0 | `round_sheet_velocity_projection_r1` | Directly addresses the strongest sheet interaction complaint with isolated logic. |
| P0 | `round_map_pin_selection_stability_r1` | Data correctness: user-selected coordinate must not be rewritten. |
| P0 | `round_map_user_location_annotation_r1` | Core map utility: user location must be visible and actionable. |
| P0 | `round_share_temp_photo_ingest_r1` | Share extension flow is broken for fallback images. |
| P0 | `round_tabbar_content_insets_r1`, `round_sheet_true_fullscreen_r1`, `round_sheet_collapsed_tabbar_clearance_r1`, `round_home_chrome_collision_r1` | Layout chain after tabbar/sheet primitives are fixed. |
| P1 | `round_button_placement_audit_r1`, `round_home_state_indicators_r1` | Important usability improvements, but best done after primary geometry is stable. |

## User Agreement Points

1. Confirm v5.9 process change: Codex GPT-5.5 is Main Operator + Orchestrator; Claude Code assists build/git/MCP/evidence/user communication.
2. Confirm P0 start order: process protocol first, then tabbar compact, sheet velocity, map pin stability, user location, share temp ingest.
3. Confirm runtime verification standard: P0 layout/location/share-extension rounds require simulator or real-device smoke evidence, not code-only review.
4. Confirm that each implementation dispatch may edit code only inside its round whitelist and may not bundle adjacent defects.

## Proposal

Adopt the listed 12 rounds as the v5.9 remediation backlog. Each round has one defect, <=3 acceptance criteria, and an explicit 3-axis verification requirement. Implementation should start only after the user accepts the roadmap and the v5.9 protocol.

## Questions

- Does the user want `REGULATION_v5_9.md` promoted into `REGULATION.md` immediately after agreement, or kept as an addendum until the first P0 dry run proves it?
- Should Dynamic Island/fullscreen verification require a real iPhone Pro device, or is iPhone 16 Pro simulator screenshot acceptable for the first pass?

## Counter / Review

Pending Claude Code Operator/user review.

## Convergence

Pending.

## Decision

Pending.

## Challenge Section

Risk: the DAG deliberately delays some visible improvements, such as state indicators and button placement, until tabbar/sheet geometry is stable. Mitigation: keep those as P1 but ready-to-dispatch specs, and do not let them merge into the P0 geometry rounds.

Rejected alternative: one broad "home UX cleanup" round. It was rejected because it repeats the prior failure mode: unclear ownership, too many acceptance checks, and no sharp runtime proof per defect.

Explicit uncertainty: real-device availability for Dynamic Island, location permission, and Share Extension fallback is not confirmed. The first implementation round must record whether simulator smoke is accepted or real-device smoke is required.
