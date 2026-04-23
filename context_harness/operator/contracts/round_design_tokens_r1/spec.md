# round_design_tokens_r1 — 디자인 토큰 재정렬 + Gowun Dodum / Nunito 폰트 번들

**Stage:** coding_1st
**Implementer:** codex
**Verifier:** codex (별도 fresh read-only session)

## Objective
zip 번들 README 의 토큰 값을 SwiftUI 구현에 완전 반영. 한글 폰트 Gowun Dodum, 영문/숫자 Nunito 를 앱 번들에 임베드하고 `UnfadingTheme.Font.*` 가 전부 `.custom(...)` 을 사용하도록 재작성. 시스템 폰트 폴백이 일어나면 UITest 로 감지 가능해야 함.

## Authoritative Source
`/Users/jeonsihyeon/factory/docs/design-docs/unfading_ref/design_handoff_unfading/README.md`

## Acceptance
1. `UnfadingTheme.Color` 의 값이 아래와 일치:
   - `bg` = `#FFF8F0`
   - `sheet` = `#FFFBF5`
   - `card` = `#FFFFFF`
   - `surface` = `#F5EEE4`
   - `primary` = `#F5998C`
   - `primaryHover` = `#E8877A`
   - `accentSoft` = `#FAE4DD`
   - `secondary` = `#8FB7A8`
   - `secondaryLight` = `#CDE2DA`
   - `textPrimary` = `#403833`
   - `textSecondary` = `#8C827A`
   - `textTertiary` = `#B8AEA5`
   - `divider` = `#EBE1D4`
   - `chipBg` = `#F5EEE4`
   - `mapBase` = `#FFF3E6`
   - `mapLand` = `#FFE8D1`
   - `mapWater` = `#DCE7E4`
   - `mapRoad` = `#F5EEE0`
   - 추가 member palette 10색 constant 로 정리
2. `UnfadingTheme.Radius`: `cardRadius = 18`, `sheetRadius = 28`, `chip = 18`, `segment = 12`.
3. `UnfadingTheme.Spacing`: 4 / 6 / 8 / 10 / 12 / 14 / 16 / 18 / 20 / 24 / 28 / 30 / 80 / 110 총 14개 constant.
4. `UnfadingTheme.Shadow`:
   - `card = .shadow(0,2,6, #403833 @ 0.04)`
   - `activeCard = .shadow(0,4,12, #F5998C @ 0.40)`
   - `overlay = .shadow(0,20,60, #403833 @ 0.25)`
   - `tabBarBorder = 0.5px solid #EBE1D4`
5. 폰트:
   - `workspace/ios/App/Fonts/GowunDodum-Regular.ttf` (Apache 2.0, OFL 가능) 번들.
   - `workspace/ios/App/Fonts/Nunito-Regular.ttf`, `Nunito-SemiBold.ttf`, `Nunito-Bold.ttf`, `Nunito-Black.ttf` (OFL) 번들.
   - `project.yml`:
     - `targets.MemoryMap.resources` 에 `App/Fonts` 디렉터리 추가.
     - `info.properties` 에 `UIAppFonts` 배열에 `.ttf` 파일명들 등록.
   - `UnfadingTheme.Font` 전면 재작성:
     - `pageTitle()` — `.custom("GowunDodum-Regular", size: 20)` weight 700 letterSpacing -0.3
     - `sectionTitle()` — size 15, weight 700, -0.2
     - `body()` — size 14, weight 500, 0
     - `chip()` — size 13, weight 700
     - `metaNum()` — `.custom("Nunito-Bold", size: 12)` tracking 0.5 uppercase
     - `tag()` — `.custom("GowunDodum-Regular", size: 10.5)` weight 500
   - 기존 `subheadlineSemibold / footnote / footnoteSemibold / title / title3Bold / caption2Semibold / captionSemibold / subheadline` 은 호환을 위해 남겨두되 내부에서 위 base font 로 mapping (예: `subheadline() = body()`, `title3Bold() = pageTitle()` 등). 삭제 금지.
6. UI surface 파일 전체에서 `.font(.system(...))` 및 `Font.system(...)` 사용 검사:
   - `workspace/ios/App`, `workspace/ios/Features`, `workspace/ios/Shared` 대상으로 `rg '\.font\(\.system|\.font\(Font\.system'` 결과 0 건.
7. PostScript name assertion 테스트:
   - `workspace/ios/Tests/UnfadingFontLoadingTests.swift` 신규.
   - `UIFont(name: "GowunDodum-Regular", size: 14)` 가 nil 이 아닌지 + 시스템 폴백 체크.
   - `UIFont(name: "Nunito-Regular", size: 12)`, `"Nunito-SemiBold"`, `"Nunito-Bold"`, `"Nunito-Black"` 각각 assert.
8. 기존 unit/UITest 전부 통과.

## Out of scope
- 컴포넌트 레이아웃 변경. 이번엔 오직 토큰 + 폰트.
- 커스텀 icon 매핑 (R27 이상 탭바 재구성에서 처리).

## 승인·검증 기준
- Verifier Codex 가 `UIFont(name:)` 테스트 + 토큰 값 diff + UI surface grep 결과 확인.
- 기존 시각적 UI 는 폰트만 바뀔 뿐 레이아웃 그대로 (이번 라운드 목표).

## 폰트 다운로드 전략
- GowunDodum: https://fonts.google.com/specimen/Gowun+Dodum (Apache 2.0)
- Nunito: https://fonts.google.com/specimen/Nunito (OFL 1.1)
- Google Fonts 공식 CDN / googlefonts/gowun-dodum github mirror 사용.
- `workspace/ios/App/Fonts/README.md` 에 라이선스 파일 경로 + 출처 URL 기록.

## Files to edit
- `workspace/ios/Shared/UnfadingTheme.swift`
- `workspace/ios/project.yml` (resources + UIAppFonts)
- `workspace/ios/App/Fonts/*.ttf` + `workspace/ios/App/Fonts/README.md` + `workspace/ios/App/Fonts/*LICENSE*` (신규)
- `workspace/ios/Tests/UnfadingFontLoadingTests.swift` (신규)
- UI surface 의 `.font(.system(...))` 전수 교체
