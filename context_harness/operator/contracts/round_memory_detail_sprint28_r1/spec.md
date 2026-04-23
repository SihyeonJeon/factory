# round_memory_detail_sprint28_r1 — Memory Detail Sprint 28 재구성

**Stage:** coding_1st
**Implementer:** codex
**Verifier:** codex (별도 fresh read-only)
**Dependencies:** R26–R31 완료.

## Objective
Prototype 섹션 5 "Memory Detail" 의 Sprint 28 순서 + "한 줄 더 쓰기" 인라인 입력을 구현.

## Authoritative Source
`docs/design-docs/unfading_ref/design_handoff_unfading/README.md` 섹션 5.

## Acceptance

### 1. 전체 구조
- Full-screen, sheet 배경.
- 상단: back / 공유 / 북마크. height 54pt safe top.

### 2. 캐러셀
- 3:4 사진 히어로. 좌/우 스와이프 또는 ←→ 버튼.
- **같은 이벤트 내 다른 추억** 간에만 이동. 다른 이벤트로 넘어가지 않음.
- `event.memories` 배열에서 현재 memory 인덱스 ± 1.

### 3. 메타 스트립
- 날짜·시간 · 날씨 · 장소 pin · 작성자 아바타.
- KST 포맷.

### 4. 노트
- `GowunDodum 15/500, line-height 1.55, text-wrap pretty`.

### 5. 태그 칩
- 감정 칩 목록 (R31 composer 에서 저장된 emotions).

### 6. 설명 요소 순서 (Sprint 28)
- **① 이 장소 다시 가볼까?** — 유사 장소 카드 2개 + 미니맵.
- **② 이벤트 안의 다른 추억들** — mini gallery.
- **③ 같이 간 사람들** — 아바타 + 이름 (general_group only).
- **④ 지출 / 날씨 상세** — 있으면 표시.

### 7. "한 줄 더 쓰기" 인라인 입력
- 하단 고정 댓글 바 아님.
- 같은 추억에 각 유저가 **1개 글 최대**.
- TextField + "저장" 버튼. 저장 시 `memories.contribution_notes` 또는 `memory_extra_notes` 테이블에 insert.
- 본 라운드: 클라이언트 UI + `@State` 로컬 저장까지. DB 스키마 추가는 **deferred** (spec 에 operator action item 기록).

### 8. MemoryDetailView 재작성
- 기존 `workspace/ios/Features/Detail/MemoryDetailView.swift` 재작성.
- 새 컴포넌트:
  - `Features/Detail/SimilarPlaceCard.swift` — ① 섹션.
  - `Features/Detail/EventMemoryMiniGallery.swift` — ② 섹션.
  - `Features/Detail/ParticipantAvatarRow.swift` — ③ 섹션.

### 9. DBMemoryExtra (optional)
- R32 에서는 클라이언트 로컬 `@State var extraLine: String` 로만.
- 실제 DB 저장은 R38 real-data round 에서.

### 10. UnfadingLocalized.Detail 확장
- `similarPlacesSection = "이 장소 다시 가볼까?"`
- `eventMemoriesSection = "이벤트 안의 다른 추억들"`
- `participantsSection = "같이 간 사람들"`
- `expenseSection = "지출"`
- `weatherSection = "날씨"`
- `addOneLineCta = "한 줄 더 쓰기"`
- `addOneLinePlaceholder = "이 추억에 한 줄 덧붙이기…"`
- `addOneLineSave = "저장"`
- 카피 톤은 커플 vs general_group 분기 (참여자 섹션은 general_group only).

### 11. 테스트
- `MemoryDetailTests` 재작성:
  - 이벤트 내 캐러셀 인덱스 바운더리.
  - general_group 시 participants 섹션 표시, couple 시 숨김.
  - "한 줄 더 쓰기" 1개 글 초과 assert.
- UITest: `testMemoryDetailOpensAndShowsSections`.

### 12. 아티팩트
- `contracts/round_memory_detail_sprint28_r1/file_whitelist.txt`
- `meetings/2026-04-23_round_memory_detail_sprint28_plan.md`
- `reports/round_memory_detail_sprint28_r1/evidence/notes.md`

### 13. 빌드·테스트
- `xcodegen generate`
- `xcodebuild test -derivedDataPath .deriveddata/r32`

## Out of scope
- DB schema 추가 (`memory_extra_notes`). R38 에서 같이.
- 날씨 API 연동 (샘플 값 사용).
- 공유 기능 구현 (button 만).
