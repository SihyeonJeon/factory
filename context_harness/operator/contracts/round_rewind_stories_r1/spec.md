# round_rewind_stories_r1 — Rewind Stories 카드 스택

**Dependencies:** R26–R33.

## Authoritative Source
README 섹션 "8. Rewind".

## Acceptance

### 1. Stories pager
- 풀스크린, `TabView(.page)` + custom progress tick bar 상단 (~4pt 높이).
- 좌/우 tap → advance/rewind. 자동 진행 5초 옵션.
- 상단 `X` close → 홈 sheet 'default' 로 복귀.

### 2. 6종 카드
- (a) **커버**: 제목 + 기간 (warm gradient 배경).
- (b) **가장 많이 간 곳 TOP 3**: 리스트.
- (c) **처음 가본 곳**: gallery (3열 grid).
- (d) **사진 가장 많이 찍은 날**: 날짜 + count + 큰 사진.
- (e) **감정 태그 클라우드**: 비율 기반 size.
- (f) **함께 보낸 시간**: 총 시간 요약.

### 3. 배경
- Warm gradient (coral / sage / lavender 중 카드 별로 선택).

### 4. RewindData 모델
- `Features/Rewind/RewindData.swift` 신규:
  - 기존 sample memories 로부터 계산. 실제 Supabase query 는 R38 이후.
  - `RewindData.sample(for period: DateInterval) -> RewindData`.

### 5. 테스트
- `RewindDataTests` — TOP 3 계산, 처음 가본 곳 필터.
- UITest `testRewindStoriesOpensAndAdvances` (home curation → rewind → tap → progress 이동) — stub 환경 의존 → 실패 시 skip.

### 6. 아티팩트
- contracts/round_rewind_stories_r1/file_whitelist.txt
- meetings/2026-04-23_round_rewind_stories_plan.md
- reports/round_rewind_stories_r1/evidence/notes.md

### 7. 빌드
- xcodegen + xcodebuild test -derivedDataPath .deriveddata/r34
