# Design Revision Workflow — Claude Design 중도 수정 → 개발 재개

**적용 대상:** 이미 구현이 진행된 상태에서 Claude Design(또는 외부 디자인 툴) 결과물로
UI/UX/비주얼 톤을 중도 수정한 뒤, 하네스(Claude + Codex + Claude Code) 위에서
개발을 재개해야 할 때.

이 문서는 "디자인 바뀌었으니 다시 만들자"를 **즉흥 구현으로 흘리지 않기 위한 체크리스트**다.
디자인 리비전은 실질적으로 제품 계약 변경이기 때문에, 브리프/검증/테마/접근성 전 층을
동시에 손봐야 드리프트가 누적되지 않는다.

관련 문서:
- [multi-agent-architecture.md](multi-agent-architecture.md) §7 (Evaluation Gates)
- [ios-architecture.md](ios-architecture.md) (네이밍·테마·접근성 기준)
- [../../context_harness/prd/ui_ux_screen_contract.md](../../context_harness/prd/ui_ux_screen_contract.md)
- [../product-specs/hf-round2-acceptance.md](../product-specs/hf-round2-acceptance.md)
- [../../SKILLS.md](../../SKILLS.md)

---

## 0. 전제 — 절대 깨지 않는 규칙

디자인이 아무리 바뀌어도 아래 항목은 항상 유지한다. 이걸 깨면 "리비전"이 아니라
"새 제품"이므로 PRD부터 다시 연다.

- 맵-퍼스트 제품 방향, 바텀시트 브라우징, `Group → DateEvent → Memory → MemoryPost` 계층
- couple / general_group 이중 모드 구조
- 저장 전 inferred place 사용자 확인, 검색/현위치 보정 루트
- 44pt 터치 타깃, Dynamic Type(시맨틱 폰트), VoiceOver 라벨
- Korean UI 텍스트, UnfadingTheme 컬러(인라인 컬러 금지)
- 작성자 ≠ 검증자 원칙, 하네스 디스패치를 통한 코드 수정(직접 편집 금지)
- 현재 테스트 스위트 카운트 유지(현재 ≥ 79) — 디자인 리비전으로 테스트가 줄면 안 된다

위 중 하나라도 **의도적으로** 변경해야 한다면 Phase 2에서 계약 문서를 먼저 갱신한 뒤
진행한다. 구현이 앞서지 않는다.

---

## Phase 0. Design Capture — 디자인 산출물 고정

목적: Claude Design에서 나온 결과물을 **재현 가능한 입력**으로 저장한다.

1. `context_harness/design/<YYYYMMDD>-<slug>/` 폴더를 생성한다.
2. 아래를 그 폴더에 저장한다:
   - 스크린별 이미지/아트보드 export (화면 이름과 1:1 매칭되는 파일명)
   - 컬러/폰트/스페이싱/반경 토큰 JSON 또는 md (숫자값 포함)
   - 주요 인터랙션/제스처 동영상 또는 캡션 GIF (가능한 경우)
   - 디자이너 메모 원문 (한국어 그대로 — 번역 금지)
3. `context_harness/design/<..>/source.md`에 다음을 기록:
   - 누가 언제 무엇을 바꾸려 했는지 (원본 대화 링크 또는 요약)
   - 리비전의 **동기**(사용자 피드백 ID, HF 라운드, 인터널 리뷰 등)
   - 교체 대상이 되는 기존 화면/섹션
4. 이 폴더는 읽기 전용이다. 이후 Phase에서 이 폴더를 수정하지 않는다 —
   변경이 필요하면 새 폴더(`<YYYYMMDD>-v2-<slug>`)를 판다.

왜 폴더 분리인가: 디자인 리비전은 **몇 번이고 다시 발생**한다. 직전 리비전의 입력을
덮어쓰면 "왜 저렇게 만들었지"를 나중에 복원할 수 없다.

---

## Phase 1. Gap Analysis — 현재 vs. 신규 차이 표

목적: 신규 디자인과 **현재 코드/계약 문서의 차이**를 숫자로 만든다. 인상평이 아니라 표다.

산출물: `context_harness/design/<..>/gap-analysis.md`

포함 항목:

| 카테고리 | 현재 | 신규 | 충격 반경 |
|----------|------|------|-----------|
| Screen inventory | 기존 화면 목록 | 신규 화면 목록 | 추가/삭제/유지 |
| Navigation | 현재 라우팅 트리 | 신규 라우팅 | 탭/모달 구조 변경 여부 |
| Component tokens | UnfadingTheme 값 | 신규 토큰 값 | 색/폰트/반경 diff |
| Interaction | 제스처/애니메이션 | 신규 | 구현 난이도 |
| Copy | 현재 한국어 문구 | 신규 문구 | 접근성 라벨 재작성 필요 여부 |
| Accessibility | 현재 VoiceOver 스크립트 | 신규 | 라벨/순서 재정의 필요 |

**`ui_ux_screen_contract.md`**와 **`ios-architecture.md`**의 어느 섹션이 영향받는지를
각 행마다 명시한다. 그 섹션이 다음 Phase의 수정 대상이다.

Codex에게 이 갭 분석을 1차 생성시키고, Claude Code가 코드베이스 실측치로 2차 검증한다.
둘의 diff는 사람이 본다.

---

## Phase 2. Contract Update — 계약 문서 선 갱신

목적: **코드를 건드리기 전에** 제품 계약과 레퍼런스 문서를 신규 디자인 기준으로 맞춘다.
이 순서를 뒤집으면 항상 드리프트가 남는다.

갱신 대상(해당 Phase 1 표에서 영향 있다고 표시된 것만):

1. `context_harness/prd/ui_ux_screen_contract.md`
   - Screen inventory, Global Navigation Model, 각 Screen 섹션
   - "Agents may change" / "may not change" 목록 재정의
2. `docs/design-docs/ios-architecture.md`
   - 네이밍, 테마 토큰, 접근성 기준 업데이트
3. `docs/references/coding-conventions.md`
   - UnfadingTheme 색/폰트 토큰 추가/변경
4. `docs/product-specs/hf-round2-acceptance.md` 또는 **새 round 파일**
   - 이번 리비전이 HF 라운드로 다뤄질 만큼 크면 `hf-round3-acceptance.md` 신설

작성자와 리뷰어를 분리한다:
- **작성:** Codex (설계·계약 문서 편집 권한)
- **리뷰:** Claude Code (코드베이스 대조, 자가승인 금지)
- **최종 승인:** 인간 (사용자) — 계약 변경은 인간 승인 없이 머지하지 않는다

---

## Phase 3. Sprint Slicing — 디스패치 단위로 쪼개기

목적: 디자인 리비전을 **1 스프린트 = 1 명확한 결과** 단위로 분해해 브리프화한다.

원칙:
- 한 스프린트당 영향 받는 화면은 최대 1~2개
- 테마 토큰 변경은 **첫 스프린트로 독립**시킨다 (후속 화면 스프린트가 공유 입력으로 쓰기 위해)
- 네비게이션 구조 변경이 있다면 그 다음 스프린트
- 화면별 리디자인 스프린트는 그 뒤에 평행 배치
- 마지막에 접근성/HIG 스위핑 스프린트 1회

브리프 파일 경로: `context_harness/handoffs/sprint<N>_design_revision_<slug>.md`

브리프 필수 항목 (CLAUDE.md §2 준수):
- 변경 목표 1~3줄
- 영향 화면 목록 + `context_harness/design/<..>/` 내 참조 이미지 경로
- 신규 토큰 값 (색/폰트/반경) — Phase 2에서 확정된 값 그대로
- **파일 화이트리스트** (수정 허용 파일 명시 — 이것 없이는 디스패치 금지)
- 깨지면 안 되는 Phase 0 규칙 복붙
- 성공 기준: 빌드 통과, 테스트 ≥ 79, 지정 화면 스크린샷 평가

브리프는 200줄을 넘기지 않는다 (CLAUDE.md §4).

---

## Phase 4. Dispatch & Implementation

순서는 CLAUDE.md §1의 역할 분배 그대로다.

1. **Claude Code**가 브리프에 따라 구현 (직접 편집 금지 — 본인도 codex CLI 경유)
2. **`xcodegen generate` → `xcodebuild test`** 통과 확인
3. 실패하면 그 안에서 해결. 테스트 수가 줄면 바로 중단하고 원인 조사.

금지 사항:
- 토큰을 중간에 손으로 덮어쓰기 (Phase 2 계약 값만 사용)
- 스프린트 범위 밖 파일 수정 (브리프 화이트리스트 밖은 손대지 않는다)
- "겸사겸사" 리팩터 — 범위를 비우지 않으면 검증이 불가능해진다

---

## Phase 5. Evaluation — 디자인 리비전 전용 게이트

기본 4 게이트 (Gate 1 빌드/테스트, Gate 2 3평가자, Gate 3 교차합의, Gate 4 프로세스 품질)에
**리비전 전용 서브 체크**를 추가한다.

Gate 2 평가자(red_team, hig_guardian, visual_qa)가 추가로 확인할 것:

- **visual_qa**: Phase 0에 저장한 스크린샷과 현재 런타임 스크린샷을 **나란히 비교**한
  reports 작성. 완벽한 픽셀 일치가 아닌 "의도 보존" 판정.
- **hig_guardian**: 신규 토큰/레이아웃이 44pt·Dynamic Type·VoiceOver 규칙을
  어기지 않는지. 어기면 BLOCKER.
- **red_team**: 기존 테스트가 신규 디자인 가정을 검증하지 못한 채 "통과"하는
  false-green이 있는지 (예: 예전 레이블로 하드코딩된 assert).

리포트는 **텍스트로 직접** 읽는다 — `extract_blockers()` 결과만 신뢰하지 않는다
(CLAUDE.md §3).

---

## Phase 6. Merge & Track

1. 스프린트 머지 판단은 **Claude Code의 2차 검증**이 한다(자가승인 불가).
2. `docs/exec-plans/sprint-history.md`에 이번 리비전 entry 추가:
   - 리비전 ID, 동기, 포함 스프린트 번호, 최종 테스트 카운트
3. `context_harness/SESSION_RESUME.md` 갱신:
   - 디자인 리비전 단계(Phase 0~6) 중 현재 위치
   - 다음 라운드로 넘어갈 준비가 되었는지
4. `docs/exec-plans/metrics.jsonl`에 토큰 사용량·BLOCKER 사이클 기록 (CLAUDE.md §9).
5. 재발 방지용 패턴이 발견되었다면 **즉시** `SKILLS.md`에 추가 (CLAUDE.md §7).

---

## Phase 7. Drift Detection — 3 스프린트 룰

CLAUDE.md §8의 드리프트 검증 주기는 리비전 중에도 유지한다.

3 스프린트마다 `ios-architecture.md` 기준 대비:
- 네이밍(신규 토큰 명도 포함) 일치
- UnfadingTheme 이외 인라인 컬러 유입 여부
- 접근성 라벨 커버리지
- 라우팅 구조가 Phase 2에서 확정한 네비게이션 모델과 일치하는지

리비전 중엔 **특히** 인라인 컬러와 하드코딩 폰트 사이즈가 슬그머니 다시 들어오기 쉽다.
이때 발견하면 별도 remediation 스프린트로 처리하고, 같은 커밋에 묻지 않는다.

---

## 빠른 결정 트리

```
신규 디자인 받음
 ├── 전제(§0) 중 하나 이상을 깨는가?
 │    ├── 예 → 제품 리브랜드. 새 PRD 라운드로 승격. 여기서 멈춤.
 │    └── 아니오 → Phase 0 진입.
 ├── Phase 1 갭 분석 결과, 변경 화면 > 3 개?
 │    ├── 예 → HF 신규 라운드로 선언 (hf-roundN-acceptance.md).
 │    └── 아니오 → 기존 라운드 안에서 리비전 스프린트 묶음으로 처리.
 └── 스프린트 수행 → 평가 → 머지 → 드리프트 감사.
```

---

## 이 문서의 유지보수

- 리비전이 끝날 때마다 "Phase N에서 놓쳤던 것" 한 줄을 맨 아래 **Lessons** 섹션에 쌓는다.
- 3 회 이상 반복된 교훈은 Phase 본문으로 승격한다.
- 문서 자체 변경도 작성자≠검증자 규칙을 따른다.

## Lessons

<!-- 리비전 종료 시 한 줄씩 append. 날짜, 교훈, 다음부터 적용할 룰. -->
