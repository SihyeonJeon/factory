---
round: feedback2_master
stage: overall_planning
status: decided
participants: [claude_code, user]
decision_id: 20260423-feedback2-10round
contract_hash: none
created_at: 2026-04-23T19:50:00Z
codex_session_id: n/a
---
# Feedback-2 (2026-04-23 실기기 테스트 후) — 10 라운드 마스터 플랜

## Source of Truth
**`docs/design-docs/unfading_ref/design_handoff_unfading/` (방금 전개된 최신본).** 이전 `Unfading Prototype.html` 은 폐기, 본 번들을 권위 있는 소스로 사용.

## User Directives (2026-04-23)
1. Codex 위주 진행, claude_code 개입 감소 (의사결정·gate·commit/push 만).
2. 5라운드씩 2번 나눠 진행.
3. 라운드마다 context 갱신 (SESSION_RESUME/SKILLS/SECURITY/meetings/reports/evidence).
4. 피드백 팀(Verifier Codex) 정교함 핵심 — Author ≠ Verifier 세션 교차 엄수.
5. 실사용 기반 평가 (시뮬레이터 XCUITest + 스크린샷 diff vs zip) 자가검증; 2–3 라운드 묶음 완료마다 사용자 실기기 합의.
6. 재사용 자산 기반 코딩. 린터/규약/거버넌스 명확.
7. Codex 가용성 이슈 발생 시 3회 재시도 → operator fallback 가능 (투명 기록).

## 디자인 격차 요약 (현재 구현 vs zip 번들)

### 블로커 급 (실기기 피드백 직접 원인)
- F-sheet-1 Collapsed sheet 가 탭바(zIndex 120)에 가림 — sheet bottom 을 탭바 위로 띄워야 함
- F-sheet-2 드래그로 최대화 불가 — Sprint 26 "내부 스크롤과 드래그 분리" 미구현
- F-sheet-3 Expanded 시 복귀 경로 없음 — SheetExpandedHeader(back/그룹/검색) 미구현

### 구조 격차
- 탭바: 디자인 = 3-tab (지도/캘린더/설정), 현재 = 5-tab. Rewind 는 홈 큐레이션 진입 카드로 위치 변경.
- Snap 비율: 디자인 0.08/0.50/1.0, 현재 0.085/0.52/1.0 (거의 일치, expanded에서 일체화 조건 차이).
- zIndex 층: 지도 10 · MapControls 26 · TopChrome 30 · FilterChipBar 28 · FAB 70 · BottomSheet 50 · ExpandedHeader 55 · TabBar **120** · 모달 200+.

### 토큰 격차
- 색: `bg: #FFF8F0` / `sheet: #FFFBF5` / `card: #FFFFFF` / `primary: #F5998C` / `primaryHover: #E8877A` / `accentSoft: #FAE4DD` / `secondary: #8FB7A8` / `secondaryLight: #CDE2DA` / `divider: #EBE1D4` / `chipBg: #F5EEE4`. 현재 일부 값 다름.
- 폰트: `Gowun Dodum` (한글 본문) + `Nunito` (숫자/영문/메타). **시스템 폴백 금지.**
- 반경: cardRadius 18, sheetRadius 28, 칩 18, 세그먼트 12.
- 그림자: 4단 (기본 카드 / 활성 CTA / 오버레이 모달 / 탭바 경계).

### 기능 격차
- GroupPickerOverlay (다중 그룹 동시 소유) 없음.
- CategoryEditorOverlay 없음.
- Composer: 장소 needs-confirm/confirmed 상태 · 24h wheel picker · 이벤트 · general_group 참여자 · 감정 7종 · 지출 없음.
- Memory Detail: Sprint 28 순서 (유사 장소 → 이벤트 내 추억 → 함께한 사람 → 지출/날씨) 미반영; "한 줄 더 쓰기" 없음.
- Calendar: 다이얼 네비 · 계획 카드(general_group) · 알림 보내기 없음.
- Rewind: 카드 스택(Stories 진행바) · 6종 카드 없음.
- Group Hub: 설정 전체 (멤버/초대/테마/알림/iCloud/export) 미완성.

## 10 라운드 스케줄

### Phase 1 (R26–R30) — 블로커 + 핵심 레이아웃 재건
Codex Challenge 에 따라 R27/R28 순서 swap: custom 3-tab shell 을 먼저 세워야 sheet 를 공통 root ZStack 안에 한 번만 구현. 기존 native TabView 안에 sheet 를 먼저 고치면 R28 때 재작업 발생.

| Round | id | 범위 |
|---|---|---|
| R26 | round_design_tokens_r1 | Theme 색/폰트/반경/간격/그림자 완전 재정렬, Gowun Dodum + Nunito 번들 임베드 + PostScript name assert 테스트 |
| R27 | round_tabbar_shell_r1 | Custom 3-tab shell (지도/캘린더/설정) + FAB 홈 오버레이 + Rewind 큐레이션 카드 진입. Root ZStack 구조 마련. UITest identifier 계약 마이그레이션 |
| R28 | round_bottom_sheet_rebuild_r1 | BottomSheet 전면 재작성 in shared root ZStack: snap 0.08/0.50/1.0, 탭바-above 바닥 고정, **UIKit UIScrollView delegate bridge** 로 Sprint26 스크롤-드래그 분리, ExpandedHeader fade + back 복귀 |
| R29 | round_home_chrome_r1 | TopChrome/FilterChipBar/MapControls/FAB 좌표+zIndex 프로토타입과 픽셀 비교 일치 |
| R30 | round_overlays_r1 | GroupPickerOverlay + CategoryEditorOverlay (active group switching 까지) |

### Phase 2 (R31–R35) — Composer/Detail/Calendar/Rewind/Group Hub
| Round | id | 범위 |
|---|---|---|
| R31 | round_composer_rebuild_r1 | Composer: needs-confirm 장소 + 24h wheel + 이벤트 분기 + general_group 참여자 + 감정 7종 + 지출, F8/F10/F11 소화 |
| R32 | round_memory_detail_sprint28_r1 | Sprint 28 순서 재구성, "한 줄 더 쓰기" 인라인 입력 |
| R33 | round_calendar_dial_r1 | 다이얼 네비 + Day Detail + general_group 계획 카드 (Sprint 29) + 알림 보내기 |
| R34 | round_rewind_stories_r1 | Stories 진행바 + 6종 카드 (커버/TOP3/처음/사진많은날/감정클라우드/함께보낸시간) |
| R35 | round_group_hub_settings_r1 | 멤버 리스트 + 초대(링크/QR) + 테마/아이콘팩 + 알림 토글 + iCloud + export |

## 각 라운드 프로토콜

1. **Plan meeting (Codex read-only fresh session)** — 라운드 spec draft 에 대해 Challenge Section (objections/risks/rejected alts) 받음. claude_code 가 수용/반영.
2. **Dispatch (Codex workspace-write fresh session)** — Swift 구현 + 라운드 아티팩트(spec/whitelist/meeting/evidence) 작성.
3. **Verifier (Codex read-only 별도 fresh session)** — Author 다른 세션. 코드 리뷰 + 시각 비교(시뮬레이터 XCUITest 스크린샷 vs zip HTML).
4. **Gate (claude_code)** — `harness/check_operator_round.py gates <round_id>`, xcodegen + xcodebuild test, commit + push.
5. **Context 갱신** — SESSION_RESUME.md 한 문단, SKILLS.md 에 재사용 배움 append, SECURITY.md 에 권한/데이터 이슈 append.

## 품질 게이트
- Unit 테스트 전부 통과 + 신규 라운드별 최소 3 tests.
- XCUITest 스크린샷 × (라운드 관련 화면) × (collapsed/default/expanded 혹은 해당 상태) 캡처 → evidence 에 저장.
- 디자인 토큰 값 하드코딩 금지 — 항상 `UnfadingTheme` 경유.
- `.font(.system(...))` 사용 금지 — `UnfadingTheme.Font.*` 만.

## 사용자 합의 포인트
- **Phase 1 smoke 범위 (R30 close 시)**: 홈 / 지도 / 시트 스냅·드래그 / 탭바 (3-tab + FAB) / GroupPicker / CategoryEditor 만. Composer / Detail / Calendar / Rewind / Group Hub 는 "known phase-2 broken" 으로 evidence 에 명시.
- Phase 2 끝(R35 close)에 최종 실기기 합의.

## Challenge Section (Codex 2026-04-23T19:55)

### 수용 (accepted)
- **R27 ↔ R28 순서 swap** — custom 3-tab shell 을 먼저 세우고 공통 root ZStack 안에서 sheet 재작성. 이유: native TabView 기반 임시 보정 낭비 방지.
- **UIKit UIScrollView delegate bridge** — Sprint 26 "시트 내부 스크롤 ↔ 드래그 분리" 를 SwiftUI simultaneousGesture 만으로 구현 시 실기기 재발 우려. `scrollViewDidScroll` + pan recognizer coordinator 로 isAtTop && downwardDrag 에서만 sheet snap 으로 넘김.
- **폰트 PostScript name assertion** — R26 acceptance 에 "실기기/UITest 에서 font name assert" 포함. 로딩 실패 시 조용한 시스템 폰트 폴백 조기 감지.
- **R28 = 테스트 마이그레이션 라운드** — 5-tab 기반 UITest (리와인드/추억 compose-intercept/localized tab labels/RootNavigationTests) 전수 재작성. R28 scope 에 이 리팩터 포함을 명시.
- **R30 독립 유지** — R35 Group Hub 와 합치지 않음. Overlay + active-group switch + scene reset 까지만.
- **Phase 1 smoke 범위 축소** — 위 "사용자 합의 포인트" 참조.
- **Verifier 모델** — 화면별 disagreement checklist + 시뮬레이터 스크린샷 + 코드 포인터 3조합. HTML diff 는 수동 기준 이미지로만.
- **R26 폰트 폴백 enforcement 범위 제한** — 전 코드베이스 전수 차단 대신 UI surface 대상 grep + acceptance 에 한정.

### Risks (top 3)
1. `R28` BottomSheet 를 native TabView 안에서 고치면 `R27` custom tab bar 때 다시 갈아엎게 된다. → **순서 swap 으로 해결**.
2. SwiftUI gesture 만으로 Sprint 26 스크롤 handoff 를 구현하면 실기기 재발. → **UIKit bridge 수용**.
3. 5-tab 제거가 UITest/접근성/네비게이션 계약 대량 파괴. → **R27 을 테스트 마이그레이션 라운드로 취급**.

### Rejected alt
- R30 과 R35 통합. 검증 표면 커지고 active-group 변경 회귀 혼입.
- R26 폰트 폴백 금지를 전 코드베이스 강제 enforcement. 과함.

---

## Revised Round Sequence (final)

| Phase | R | id |
|---|---|---|
| 1 | R26 | round_design_tokens_r1 |
| 1 | R27 | round_tabbar_shell_r1 |
| 1 | R28 | round_bottom_sheet_rebuild_r1 |
| 1 | R29 | round_home_chrome_r1 |
| 1 | R30 | round_overlays_r1 |
| 2 | R31 | round_composer_rebuild_r1 |
| 2 | R32 | round_memory_detail_sprint28_r1 |
| 2 | R33 | round_calendar_dial_r1 |
| 2 | R34 | round_rewind_stories_r1 |
| 2 | R35 | round_group_hub_settings_r1 |

## 위험·주의
- Codex capacity 불안정 — 각 round 3회 재시도 후 operator fallback. evidence 에 투명 기록.
- `Gowun Dodum` / `Nunito` `.ttf` 번들 수급 필요 (Google Fonts 오픈소스, Apache/OFL). R26에서 `.ttf` 다운로드 + `project.yml resources` 등록.
- Prototype 은 SHEET_STATES `{collapsed: 0.085, default: 0.52, expanded: 1.0}` 으로 쓰지만 README 는 `0.08 / 0.50 / 1.0` — **README 우선** (최신 핸드오프).
