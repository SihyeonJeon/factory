# Factory Session Resume — 2026-04-23 (Phase 1 완료)

**Source of Truth (design):** `docs/design-docs/unfading_ref/design_handoff_unfading/` (README + Prototype HTML, 2026-04-23 최신본).

## 오늘 완료 블록 요약

### Block A (아침 8h): R3–R14 deepsight UI 최초 빌드
97/97 tests (90 unit + 7 UITest). 로컬 영속성만.

### Block B (오후): R15–R24 Supabase 통합
129/129 + 2 skip E2E. Supabase schema + Auth + Groups + Memories + Photos + StoreKit + AppIcon + Privacy + TestFlight script.

### Block C (저녁): R25 그룹 UX + Feedback-1 (14건) 병렬 스트림
S0 backend RLS fix (recursion 해소) + A (sheet stream A) + B (composer location) + C2 (calendar plans).

### **Block D (밤): Phase 1 Feedback-2 (zip 최신 디자인 기반 10 라운드 중 5 완료)**

| Round | id | 핵심 |
|---|---|---:|
| **R26** | round_design_tokens_r1 | 디자인 토큰 재정렬 (README 기준), Gowun Dodum + Nunito 4-weight `.ttf` 번들 + PostScript name 검증 테스트 | 1758aa3 |
| **R27** | round_tabbar_shell_r1 | Custom 3-tab shell (지도/캘린더/설정) + ComposeFAB 홈 오버레이 + Rewind 큐레이션 카드 진입 | 9feb7e0 |
| **R28** | round_bottom_sheet_rebuild_r1 | BottomSheet 재작성: 탭바-above 좌표계, UIKit UIScrollView delegate bridge (Sprint 26), SheetExpandedHeader back 버튼 | eca93b2 |
| **R29** | round_home_chrome_r1 | TopChrome/FilterChipBar/MapControls 좌표 정밀화 + zIndex + chrome fade + `-UI_TEST_SHEET_SNAP` 런치 arg | 4f5e2f5 |
| **R30** | round_overlays_r1 | GroupPickerOverlay + CategoryEditorOverlay + CategoryStore 영속성 | (next) |

## 현재 테스트 상태
163 passed + 8 skipped (전체 171 UITest/unit 중):
- 2 E2E (UNFADING_E2E_* env 미설정 시 항상 skip)
- 4 Sheet gesture UITest (simulator 5pt handle swipe 불안정 — 실기기 smoke 위임)
- 1 Form identifier (R35 Group Hub 재작업 시 활성화)
- 1 FilterChipBar `+` 버튼 offscreen (실기기 smoke 위임)

## Phase 1 → Phase 2

Phase 1 완료: Feedback-2 의 3가지 sheet 블로커 + 레이아웃 재건 + 폰트/토큰/overlay UI.

**실기기 smoke test 권장 시점: 지금 (R30 직후).**

```
cd /Users/jeonsihyeon/factory && git pull origin master
open workspace/ios/MemoryMap.xcodeproj
```

실기기에서 확인할 항목:
1. Sheet collapsed 가 탭바에 가리지 않음 + 핸들 드래그로 expanded 이동 가능 (F1/F2)
2. Expanded 시 SheetExpandedHeader 의 back 버튼으로 default 복귀 (F3)
3. 3-tab (지도/캘린더/설정) + 홈 FAB
4. 홈 큐레이션의 "이번 달 리와인드" 카드로 Rewind 진입
5. TopChrome tap → GroupPickerOverlay
6. FilterChipBar `+` → CategoryEditorOverlay
7. Gowun Dodum / Nunito 폰트 렌더

Phase 2 (R31–R35) 대기: composer 재작성(F8/F10/F11 포함) / Memory Detail Sprint 28 / Calendar 다이얼 + 계획 카드 / Rewind Stories / Group Hub.

## 하네스 상태
v5.7 (Swift delegation + 다중 축 평가 + vibe-coding regulation + CHANGELOG meeting trail).
Feedback-2 10-round 전 과정: Codex operator Challenge Section 수용, R27/R28 순서 swap 반영, UIKit UIScrollView delegate bridge 채택.

Codex capacity 불안정 대응: 3회 재시도 정책 유지, 대부분 성공. R29 1회 stream disconnect 후 재시도 성공.

## 아티팩트 위치
- Plan: `context_harness/operator/meetings/2026-04-23_feedback2_10round_plan.md`
- 각 라운드: `context_harness/operator/contracts/round_<name>_r1/` + `meetings/...` + `reports/.../evidence/`
- 실기기 테스트 계정: `tester@unfading.app` / `UnfadingTest1!`
