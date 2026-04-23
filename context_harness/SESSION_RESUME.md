# Factory Session Resume — 2026-04-24 (R26-R39 통합 완료, R40 Phase 2 final)

**Source of Truth (design):** `docs/design-docs/unfading_ref/design_handoff_unfading/` (README + prototype HTML, 2026-04-23 최신본).

## 통합 상태

- Phase 1 complete: R26-R30
- Phase 2 complete: R31-R35
- Launch/TestFlight prep complete: R36-R39
- Current consolidation round: R40 Phase 2 final docs + regression/testflight prep validation

## R26-R39 요약

| Round | id | 핵심 |
|---|---|---|
| R26 | `round_design_tokens_r1` | Gowun Dodum + Nunito 번들, 토큰 정리, 폰트 검증 테스트 |
| R27 | `round_tabbar_shell_r1` | Custom 3-tab shell + 홈 FAB + Rewind 진입 |
| R28 | `round_bottom_sheet_rebuild_r1` | BottomSheet 재작성, expanded back, scroll/drag 좌표계 안정화 |
| R29 | `round_home_chrome_r1` | TopChrome / FilterChipBar / MapControls 재배치 + fade |
| R30 | `round_overlays_r1` | GroupPickerOverlay + CategoryEditorOverlay + active-group 전환 |
| R31 | `round_composer_rebuild_r1` | Composer 전면 재작성: place confirm, event binding, participants, emotions, cost |
| R32 | `round_memory_detail_sprint28_r1` | Memory Detail Sprint 28 구조, same-event carousel, inline extra line |
| R33 | `round_calendar_dial_r1` | 월 picker, day detail, general-group 계획 카드, RSVP/알림 토스트 |
| R34 | `round_rewind_stories_r1` | Stories 기반 Rewind 6종 카드 |
| R35 | `round_group_hub_settings_r1` | Settings 진입 Group Hub 확장, 멤버/초대/appearance/data placeholder |
| R36 | `round_ship_assets_r1` | ship-ready asset/stub 정리 및 제출면 보강 |
| R37 | `round_storekit_r1` | 로컬 StoreKit paywall + entitlement 상태 표시 |
| R38 | `round_launchability_r1` | launchability 체크, screenshot surface, 앱 제출 전 점검 |
| R39 | `round_e2e_testflight_r1` | Supabase E2E skip-safe 추가, archive/export helper, screenshot harvest helper |

## 현재 검증 상태

- Source test inventory: 176 unit + 28 UITest = 204 test methods.
- Requested R40 command:
  - `xcodebuild test -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath .deriveddata/r40 -resultBundlePath .deriveddata/r40/Test-R40.xcresult`
- Result in current workspace-write sandbox:
  - `.deriveddata/r40/Test-R40.xcresult` 생성
  - status `failedToStart`
  - executed tests `0`
  - blockers: `CoreSimulatorService connection became invalid`, denied writes to `/Users/jeonsihyeon/.cache/clang/ModuleCache` and `~/Library/Caches/org.swift.swiftpm/...`
- `scripts/harvest_screenshots.sh` 실행 시도:
  - R40 evidence screenshot export `0` files
  - `xcresulttool` export 권한 오류로 harvest 미완료
- Script validation:
  - `bash -n workspace/ios/scripts/archive.sh` passed
  - `bash -n workspace/ios/scripts/harvest_screenshots.sh` passed
  - `plutil -lint workspace/ios/scripts/export-options.plist` passed

## Deferred → Phase 3 (R41-R50)

1. Apple Sign in
2. Edge Function receipt validation via App Store Server API
3. Supabase HIBP leaked-password protection toggle
4. Real signed TestFlight archive/export/upload

## 아티팩트

- Launchability review: `docs/product-specs/launchability-review-2026.md`
- Phase 2 release notes: `docs/product-specs/phase2_release_notes_2026-04-24.md`
- Phase 2 final contract: `context_harness/operator/contracts/round_phase2_final_r1/`
- Phase 2 final meeting: `context_harness/operator/meetings/2026-04-24_phase2_final.md`
- R40 evidence: `context_harness/reports/phase2_final/evidence/`
