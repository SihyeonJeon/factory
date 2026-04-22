# Sprint History — Pre-v5 Archive (UNVERIFIED)

> ⚠️ **IMPORTANT:** This file contains narrative history that was carried forward in
> `SESSION_RESUME.md` as active state prior to `round_foundation_reset_r1`. The actual
> `workspace/ios/` state at round 2 kickoff (2026-04-23) does NOT match this narrative
> (MVP scale, 12 Swift files, 10 tests, 3 tabs, no `UnfadingTheme`, English UI).
>
> This file exists so the information is not deleted, but it **MUST NOT** be cited
> as truthful current-state information. Treat as "history of what was documented,
> not necessarily what was built in this repo."

## Origin of the discrepancy

The active `SESSION_RESUME.md` (through 2026-04-22) described an app at Sprint 51
with 140 tests, HF Rounds 1-6 + 5 Remediation + Autonomous Loop complete. The
workspace reality observed at `round_foundation_reset_r1` contract creation does
not reflect that: `workspace/ios/` is an early MVP (Map/Rewind/Groups tabs, 10
tests, English strings, no theme namespace). Possible explanations include a
parallel track that never synced into this repo, narrative drift over multiple
sessions, or an early workspace reset whose history was not reconciled.

Per user directive (2026-04-23): autonomous harness loop will resolve gaps using
spec/convention/governance/linter discipline. This archive and the truthful
`SESSION_RESUME.md` rewrite are part of `round_foundation_reset_r1` deliverables.

---

## Archived delivery-status narrative (pre-v5, unverified)

### HF Round 1: 10/10 complete
### HF Round 2: 12/12 complete (Sprint 11-15 + 3 remediations)
### Round 3: 4/4 complete (Sprint 16-19)
### HF Round 3: 4/4 + 2 remediation (Sprint 20-25)
### HF Round 4: 4/4 + 1 remediation (Sprint 26-30)
### HF Round 5: 5/5 (Sprint 31-35)
### S-17 Remediation: 5/5 (Sprint 36-40)
### HF Round 6: 3/3 (Sprint 46-48)
### Autonomous Loop: 3/3 (Sprint 49-51)

| Sprint | Content | Reported result |
|--------|---------|-----------------|
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
| 33 | HF5: 장소 검색 제거, 모임 swap→Settings 이동 | 87/87 PASS |
| 34 | HF5: 클러스터 마커 centroid 위치 수정 | 87/87 PASS |
| 35 | HF5: 바이브 코딩 안티패턴 분석, SKILLS.md S-17 섹션 추가 | — |
| 36 | S-17: 인라인 컬러 → UnfadingTheme 토큰 | 87/87 PASS |
| 37 | S-17: try? → do-catch + os.Logger | 87/87 PASS |
| 38 | S-17: [weak self] 누락 감사 | 93/93 PASS |
| 39 | S-17: scenePhase 라이프사이클 + draft 저장/복원 | 93/93 PASS |
| 40 | S-17: AuthManager UserDefaults → Keychain 마이그레이션 | 93/93 PASS |
| 41 | Dead code 정리 + EditButton 접근성 | 93/93 PASS |
| 42 | 테스트 커버리지 확장 | 131/131 PASS |
| 46 | HF6: Bottom sheet 인터랙션 | 121 unit GREEN |
| 47 | HF6: 하단 탭 바 재설계 (5탭) | 121 unit GREEN |
| 48 | HF6: 사진 그리드 4열 + 버튼 구조 감사 | 121 unit GREEN |
| 49 | Autonomous Cycle 1: 빈 상태 UX 강화 | 135/135 PASS |
| 50 | Autonomous Cycle 2: 햅틱 피드백 시스템 | 135/135 PASS |
| 51 | Autonomous Cycle 3: 마이크로 인터랙션 | 140/140 PASS |

## Archived pre-v5 advisory list

1. ~~`try?` 5곳 에러 무시~~ → reported RESOLVED (Sprint 37)
2. ~~인라인 컬러 6+ 파일~~ → reported RESOLVED (Sprint 36)
3. ~~`[weak self]` 부재~~ → reported RESOLVED (Sprint 38)
4. ~~UserDefaults 인증 (Keychain 미사용)~~ → reported RESOLVED (Sprint 40)
5. ~~`scenePhase` 감시 부족~~ → reported RESOLVED (Sprint 39)

Open pre-v5 advisory items (as reported, now moot because the referenced files
do not exist in this workspace):

6. Dark mode 미지원 (`.preferredColorScheme(.light)`)
7. Supabase Swift SDK 미추가 (canImport guard)
8. `DomainEvent.isMultiDay` 저장값 drift
9. `MemoryDetailView` 사진 캐러셀 `width: 260` 고정
10. Runtime warnings: missing `default.csv`, SF Symbol
11. 7 Swift 파일 accessibilityLabel 누락

## Archived Runtime QA Pipeline claims

- XCUITest target (`project.yml` UnfadingUITests) — NOT present in current workspace
- 10 UI tests (launch/sheet/archive/calendar/plan/group swap/map/settings/tab tour/composer) — NOT present
- `harness/runtime_qa.py` RuntimeQAPipeline — present in `harness/` but untested against current MVP

## Relationship to round_foundation_reset_r1

The foundation reset round accepts the truthful baseline (10 unit tests MVP) and
rebuilds reusable Swift assets (`UnfadingTheme`, `UnfadingLocalized`,
`UnfadingPrimaryButtonStyle`, `UnfadingCardBackground`) that the pre-v5 narrative
claimed but the workspace never had. Future rounds proceed per
`docs/design-docs/deepsight_slicing_manifest.md`.
