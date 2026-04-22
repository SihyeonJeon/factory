# Factory Session Resume — 2026-04-22

**Single source of truth for resuming development.**

---

## 0. Harness v5 Bootstrap (2026-04-19)

**Status:** ACTIVE. Replaces v4.

**Read first this session:**
1. Your loader: `.claude/CLAUDE.md` (Claude Code Operator) or `AGENTS.md` (Codex Operator)
2. Shared persona: `context_harness/operator/OPERATOR.md`
3. Index: `context_harness/operator/FILE_INDEX.md`
4. Precedence + locks + Gate 5: `context_harness/operator/REGULATION.md`
5. Stage matrix + ownership: `context_harness/operator/STAGE_CONTRACT.md`

**Key changes from v4:**
- Claude Code + Codex are EQUAL co-operators. No principal/secondary.
- Every stage has 1 Performer + 1 Cross-Validator. See STAGE_CONTRACT §1.
- Round contracts + locks enforce immutability. Base files never edited post-lock.
- Meetings require Challenge Section (objection/risk/rejected alt/uncertainty). Fake dissent forbidden.
- Gate 5 added (process integrity). Gate 5 blockers: lock mapping, contract mutation, missing challenge section, FILE_INDEX coverage, lint hash, operator-layer drift.
- Gemini = advisory only (tier-3, technical disputes). Never routine.
- Real-use eval split: rubric=Codex, capture=Claude Code (evidence only, no verdict), review=Codex.
- Precedence ladder: active round contract+lock > REGULATION > STAGE_CONTRACT > OPERATOR > domain workflows > legacy docs.
- `docs/design-docs/multi-agent-architecture.md` marked **SUPERSEDED** (still readable for history; may not be cited to override v5).

**Bootstrap meeting:** [`operator/meetings/2026-04-19_v5_kickoff.md`](operator/meetings/2026-04-19_v5_kickoff.md) — 3-round peer review, CONVERGED.
**Drift fix (v5.1, 2026-04-22):** [`operator/meetings/2026-04-22_v5_bootstrap_drift.md`](operator/meetings/2026-04-22_v5_bootstrap_drift.md) — Codex stop-hook review caught 12 blockers + 3 advisories; all resolved as routine amendments. Checker expanded with `close` subcommand, live hash checks, commit traceability, factual-evidence enforcement, operator-layer drift audit.

**Drift fix (v5.2, 2026-04-22):** [`operator/meetings/2026-04-22_v5.2_drift_fix.md`](operator/meetings/2026-04-22_v5.2_drift_fix.md) — Second stop-hook review caught 7 blockers + 3 advisories. Routine amendments.

**Bypass fix (v5.3, 2026-04-22):** [`operator/meetings/2026-04-22_v5.3_bypass_fix.md`](operator/meetings/2026-04-22_v5.3_bypass_fix.md) — Third stop-hook moved from drift to enumerating **11 specific governance exploits**. Codex recommended **block**. Converged on trust model (**honest-agent + tamper-evident**; not malicious-fabrication resistant). Implemented: per-round `locks/<round>.events.jsonl` with lock sha validation, amendment disk-scan + strict metadata, strict gate_evidence schema with artifact hashes, `codex_session_id`/`codex_transcript` identity presence, `stages_completed` demoted to informational, `cmd_lock` refuses pre-existing amendments, codex transcripts persisted at `operator/codex_transcripts/`.

**Checker:** `python3 harness/check_operator_round.py lint|gates <round>|audit-operator-layer|lock <round>|close <round>`. Post-v5.3: **0 blockers, 1 advisory (allowlisted future path), 17 passes.**

**Next round:** Deepsight redesign processing (8-screen prototype at `docs/design-docs/travel_deepsight/`). Sliced per `design-revision-workflow.md` Phase 3.

**Round 1 (deepsight_r1) — CLOSED 2026-04-22T12:16Z:**
- Scope: contract-only (no Swift). Deliverables: `docs/design-docs/deepsight_tokens.md`, `deepsight_gap_analysis.md`, `deepsight_slicing_manifest.md`.
- Meeting: `operator/meetings/2026-04-22_round1_deepsight_plan.md` (decided)
- Contract: `operator/contracts/round_deepsight_r1/` (6 base + 1 gate_evidence.json)
- Lock: `status: closed`, `base_commit: 791874f`, `gate_evidence_sha256: sha256:46945f05...` (events: created → closed)
- Verdict: `reports/round_deepsight_r1/verdict.md` — PASS with 3 advisories
- Key advisory: `UnfadingTheme.swift` missing in workspace despite doc references → must resolve in token sprint round
- **Codex blocker triage from real use:** #1 (no amend cmd) confirmed REAL ×2; #4 (post-close evidence tampering not detected) confirmed REAL via empirical test. Both P0 for v5.4. Others (#2, #3, #5, #6, #7, #10) not exercised this round.

---

## 1. Current State

| Item | Status |
|---|---|
| Date | 2026-04-22 |
| Branch | `master` |
| App name | **Unfading** |
| Last green | Sprint 51 (140/140 — Unit 130 + UI 10) |
| Tests | 130 unit + 10 XCUITest = 140 total |
| Integration worktree | `/Users/jeonsihyeon/factory/.worktrees/_integration` |
| Supabase | 7 tables, RLS enabled, MCP connected |
| Architecture version | **v5.3** (v5.2 + tamper-evident lock events + strict amendment + gate_evidence schema + codex identity presence + trust model ratified) |
| Runtime QA | XCUITest pipeline integrated — `harness/runtime_qa.py` |
| Operator checker | `harness/check_operator_round.py` (v5.1) — lint + audit + close; 0 blockers |

---

## 2. Delivery Status

### HF Round 1: 10/10 complete
### HF Round 2: 12/12 complete (Sprint 11-15 + 3 remediations)
### Round 3: 4/4 complete (Sprint 16-19)
### HF Round 3: 4/4 + 2 remediation (Sprint 20-25)
### HF Round 4: 4/4 + 1 remediation (Sprint 26-30)
### HF Round 5: 5/5 (Sprint 31-35)
### S-17 Remediation: 5/5 (Sprint 36-40)
### HF Round 6: 3/3 (Sprint 46-48)
### Autonomous Loop: 3/3 (Sprint 49-51)

| Sprint | Content | Result |
|--------|---------|--------|
| 20 | HF3: animation, search bar, map controls, location permission | 77/77 PASS |
| 21 | HF3: sheet full-screen, 메인/보관함 tabs | 77/77 PASS |
| 22 | HF3: calendar dial picker, time wheel | 77/77 PASS |
| 23 | HF3: marker→sheet, back button, cluster filter | 77/77 PASS |
| 24 | HF3 remediation: coordinator, textOnPrimary, 44pt, race | 77/77 PASS |
| 25 | Drift fix: .foregroundStyle(.white) → textOnPrimary/textOnOverlay (20건) | 77/77 PASS |
| 26 | HF4: sheet clip/fullscreen, year comma, back chevron | 77/77 PASS |
| 27 | HF4: archive event grouping (sectioned LazyVStack) | 77/77 PASS |
| 28 | HF4: detail redesign (prev/next fix, weather, nav bar) | 77/77 PASS |
| 29 | HF4: calendar planning + group swap | 77/77 PASS |
| 30 | HF4 remediation: CalendarView group filter + reaction label | 77/77 PASS |
| 31 | HF5: 컴포저 fullscreen 전환, 키보드 dismiss, 사진 섹션 최상단 이동 | 77/77 PASS |
| 32 | HF5: 바텀시트 핸들 전용 드래그, 네이버맵 스타일 헤더 fade-in, 내부 스크롤→시트 크기 분리 | 77/77 PASS |
| 33 | HF5: 장소 검색 제거(이벤트+추억만), 모임 swap→Settings 이동, 검색 오버레이 크기 조정 | 87/87 PASS |
| 34 | HF5: 클러스터 마커 centroid 위치 수정 (CentroidClusterAnnotation 서브클래스) | 87/87 PASS |
| 35 | HF5: 바이브 코딩 안티패턴 분석, SKILLS.md S-17 섹션 추가 (22개 체크리스트) | — |
| 36 | S-17: 인라인 컬러 → UnfadingTheme 토큰 (8파일, 4토큰 추가) | 87/87 PASS |
| 37 | S-17: try? → do-catch + os.Logger (3곳 변환) | 87/87 PASS |
| 38 | S-17: [weak self] 누락 감사 (2파일 수정: PlaceSearchService, PhotoLoader) | 93/93 PASS |
| 39 | S-17: scenePhase 라이프사이클 + draft 저장/복원 (6 신규 테스트) | 93/93 PASS |
| 40 | S-17: AuthManager UserDefaults → Keychain 마이그레이션 | 93/93 PASS |
| 41 | Dead code 정리 (64줄 제거) + EditButton 접근성 | 93/93 PASS |
| 42 | 테스트 커버리지 확장 (38개 신규: Rewind, Groups, Calendar, Keychain, EmotionTag, GroupInvitation, DomainMemory) | 131/131 PASS |
| 46 | HF6: Bottom sheet 인터랙션 5건 (진동 제거, overscroll 축소, 상단 드래그, 뒤로가기, 핸들 확대) | 121 unit GREEN |
| 47 | HF6: 하단 탭 바 재설계 (5탭: 지도/캘린더/추억생성/되감기/설정, FAB→중앙, island→full bar) | 121 unit GREEN |
| 48 | HF6: 사진 그리드 4열 + 버튼 구조 감사 7건 수정 | 121 unit GREEN |
| 49 | Autonomous Cycle 1: 빈 상태 UX 강화 — DayMemoriesList/RewindFeedView CTA 추가, +4 테스트 | 135/135 PASS |
| 50 | Autonomous Cycle 2: 햅틱 피드백 시스템 — sensoryFeedback 3종 (selection/impact/success), 4파일 | 135/135 PASS |
| 51 | Autonomous Cycle 3: 마이크로 인터랙션 — UnfadingPressButtonStyle 47곳 전환, SyncErrorBanner 추가, +5 테스트, 18파일 | 140/140 PASS |

---

## 3. HF Round 5 Changes Summary

| 항목 | 변경 내용 |
|------|-----------|
| 컴포저 | fullScreenCover 전환, 키보드 dismiss, 사진 섹션 최상단 이동 |
| 바텀시트 | 핸들 전용 드래그, expandedHeaderBar fade-in, handleDragProgress |
| 홈 화면 | 장소 검색 제거 (이벤트+추억만), 그룹 피커 제거 |
| 설정 | "활성 모임" 섹션 추가 (모임 swap 이동) |
| 클러스터 | CentroidClusterAnnotation 서브클래스로 centroid 위치 수정 |
| SKILLS.md | S-17 바이브 코딩 안티패턴 방지 규율 (22개 체크리스트) |

### 주요 수정 파일

- `UnfadingHomeView.swift` — fullScreenCover, 그룹 피커 제거, 장소 검색 제거
- `MemoryComposerSheet.swift` — 사진 섹션 최상단, 키보드 dismiss
- `MainBottomSheet.swift` — 핸들 전용 드래그, expandedHeaderBar, handleDragProgress
- `SettingsView.swift` — "활성 모임" 섹션 추가
- `MemoryAnnotation.swift` — CentroidClusterAnnotation 추가
- `MemoryClusterMapView.swift` — centroid 클러스터 델리게이트
- `SKILLS.md` — S-17 바이브 코딩 안티패턴 방지 규율

---

## 3a. S-17 Remediation Changes Summary (Sprint 36-40)

| 항목 | 변경 내용 |
|------|-----------|
| 테마 토큰 | UnfadingTheme에 4 토큰 추가, 8파일 인라인 컬러 제거 |
| 에러 처리 | try? → do-catch + os.Logger (3곳) |
| 메모리 안전 | [weak self] 누락 수정 (PlaceSearchService, PhotoLoader) |
| 라이프사이클 | scenePhase 감시 + draft 저장/복원 시스템 |
| 보안 | AuthManager UserDefaults → Keychain 마이그레이션 |

### 주요 수정 파일

- `UnfadingTheme.swift` — 4 토큰 추가
- `MemoryGalleryView.swift`, `MemoryBriefView.swift`, `MemoryPinMarker.swift`, `MemoryClusterMapView.swift`, `DiaryCoverCustomizationView.swift`, `YearEndReportView.swift` — 인라인 컬러 수정
- `MemoryComposerSheet.swift` — do-catch + draft 저장/복원
- `GroupHubView.swift` — do-catch
- `PlaceSearchService.swift`, `PhotoLoader.swift` — [weak self]
- `KeychainHelper.swift` (신규) — Keychain 래퍼
- `AuthManager.swift` — Keychain 마이그레이션
- `ComposerDraftStorage.swift` (신규) — draft 저장 시스템

---

## 3b. HF Round 4 Changes Summary

| 항목 | 변경 내용 |
|------|-----------|
| 시트 스크롤 | .clipped()로 내용 경계 밖 표시 방지 |
| 시트 전체화면 | expanded 시 height=infinity, safeArea 무시, 핸들 숨김 |
| 캘린더 년도 | Text(verbatim:)으로 반점 제거 |
| 뒤로 버튼 | 핸들 극좌측 chevron.left 아이콘만 |
| 보관함 | 이벤트별 섹션 그룹 (이벤트명+날짜+추억수 헤더) |
| 추억 상세 | 이전/다음 동작 수정, 날씨 카드, n/total 네비, 요소 재구성 |
| 캘린더 계획 | 미래 이벤트 보라색 점, 계획 추가 시트, DayMemoriesList 통합 |
| 모임 스왑 | 상단 그룹 선택 버튼, 지도/보관함/캘린더 연동 필터링 |
| DomainMemory | weather: String? 필드 추가 |
| DomainEvent | isPlanned computed property 추가 |
| GroupStore | selectedGroupID, selectGroup(id:) 추가 |

---

## 3c. HF Round 6 Changes Summary (Sprint 46-48)

| 항목 | 변경 내용 |
|------|-----------|
| 바텀시트 | 진동 제거, overscroll 축소, 상단 드래그, 뒤로가기, 핸들 확대 |
| 탭 바 | 5탭 구조 전면 재작성 (지도/캘린더/추억생성/되감기/설정), FAB→중앙 탭, island→full bar |
| 사진 그리드 | 4열 레이아웃 |
| 접근성 | 버튼 구조 감사 7건 수정 (44pt 터치 타겟, disabled 상태 강화) |

### 주요 수정 파일

- `MainBottomSheet.swift` — 진동 제거, overscroll, 상단 드래그, 뒤로가기, 핸들
- `TabRouter.swift` — compose/rewind 탭 추가
- `RootTabView.swift` — 5탭 구조 전면 재작성
- `UnfadingHomeView.swift` — FAB 제거, 컴포저 위임
- `MemoryGalleryView.swift` — 4열 그리드
- `GroupHubView.swift` — EditButton 제거, 44pt 터치 타겟
- `SettingsView.swift` — disabled 상태 강화
- `MemoryBriefView.swift` — disabled ButtonStyle 개선

---

## 4. Architecture v4 Changes (from v3)

- Agent role restructure: Claude Code = implementer + 2nd verifier, Codex = planner + 1st verifier
- Process quality evaluation (Gate 4): remediation cycles, BLOCKER recurrence, brief accuracy, drift latency
- Co-planning: Codex + Claude Code joint detailed design
- All v3 infrastructure retained (3-layer memory, SKILLS.md, process-log, verify-before-use, drift detection)

---

## 5. Key Files (Topic Layer)

| File | Purpose |
|---|---|
| `docs/design-docs/multi-agent-architecture.md` | v4 멀티에이전트 아키텍처 |
| `docs/design-docs/ios-architecture.md` | iOS 앱 구조 |
| `docs/references/coding-conventions.md` | 코딩 컨벤션 + 금지 영역 |
| `docs/product-specs/hf-round2-acceptance.md` | HF2 수용 기준 |
| `docs/exec-plans/sprint-history.md` | 전체 스프린트 이력 |
| `docs/exec-plans/process-log.jsonl` | 에이전트 활동 로그 |
| `SECURITY.md` | 보안 규칙 |
| `SKILLS.md` | 검증된 패턴 (17항목, S-17 바이브 코딩 안티패턴 포함) |

---

## 6. Runtime QA Pipeline

| Component | Status |
|-----------|--------|
| XCUITest target | `project.yml` UnfadingUITests added |
| Test cases | 10 tests (launch, sheet, archive, calendar, plan, group swap, map, settings, tab tour, composer) |
| Screenshot extraction | xcresulttool activities API + legacy export |
| Harness integration | `master_router.py` RUNTIME_QA task type + `runtime_qa()` convenience |
| Pipeline module | `harness/runtime_qa.py` RuntimeQAPipeline class |

## 7. Process Audit Results (2026-04-14)

| Check | Result | Detail |
|-------|--------|--------|
| S-1 xcodegen before xcodebuild | PASS | Consistent across all 30 sprints |
| S-4 44pt touch targets | PASS | Fixed Sprint 24, no recurrence |
| S-6 Dynamic Type | FIXED | `.system(size:16)` found in group swap icon → changed to `.subheadline` |
| S-11 Three-evaluator | PARTIAL | Codex often empty → Claude fallback, reducing diversity |
| S-12 Runtime screenshot | PASS | XCUITest pipeline now operational |
| Inline colors | ADVISORY | `Color.black.opacity(0.45)` remains (1 instance) |
| Missing a11y labels | ADVISORY | 7 files missing accessibilityLabel in Features/ |
| Remediation cycles | PASS | ≤2 per round |
| BLOCKER recurrence | PASS | 0 after SKILLS registration |
| SKILLS usage | PASS | ~3% miss rate |

## 7a. Autonomous Loop Summary (Sprint 49-51)

| Metric | Value |
|--------|-------|
| Total sprints (31-51) | 21 |
| Failures | 0 |
| Test progression | 77 → 140 |
| HF items processed | R5 12건 + R6 6건 |

## 8. Next Steps

인간 피드백 대기 또는 추가 자율 개선.

**Advisory items (S-17 분석에서 발견) — 모두 해결됨:**
1. ~~`try?` 5곳 에러 무시~~ → RESOLVED (Sprint 37, do-catch + os.Logger)
2. ~~인라인 컬러 6+ 파일~~ → RESOLVED (Sprint 36, UnfadingTheme 토큰)
3. ~~`[weak self]` 부재~~ → RESOLVED (Sprint 38, PlaceSearchService + PhotoLoader)
4. ~~UserDefaults 인증 (Keychain 미사용)~~ → RESOLVED (Sprint 40, Keychain 마이그레이션)
5. ~~`scenePhase` 감시 부족~~ → RESOLVED (Sprint 39, draft 저장/복원)

**기존 advisory (미해결):**
6. Dark mode 미지원 (`.preferredColorScheme(.light)`)
7. Supabase Swift SDK 미추가 (canImport guard)
8. `DomainEvent.isMultiDay` 저장값 drift 위험 → computed property 전환 권장
9. `MemoryDetailView` 사진 캐러셀 `width: 260` 고정 (Dynamic Type 미대응)
10. Runtime warnings: missing `default.csv`, SF Symbol (non-blocking)
11. 7 Swift 파일 accessibilityLabel 누락 (Features/ 내)
