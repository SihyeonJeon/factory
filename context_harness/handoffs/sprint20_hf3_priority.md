# Sprint 20 — HF Round 3 최우선 수정

**Date:** 2026-04-14
**Source:** Human Feedback Round 3
**Goal:** 애니메이션 반복 제거, 검색 바 정리, 위치/나침반 버튼 재배치, 앱 시작 시 위치 권한

---

## Fix 1: Bottom Sheet 애니메이션 반복 제거

**문제:** 사용자가 시트를 조절한 뒤 snap 애니메이션이 한 번 더 출력됨.

In `Features/Home/MainBottomSheet.swift`:
- `dragGesture` `.onEnded`에서 `withAnimation(Self.snapSpring)` 호출 시 detent 변경 → 그런데 `@GestureState dragTranslation`이 리셋되면서 또 한번 높이 변화가 발생하여 이중 애니메이션이 보임.
- **Fix:** `.onEnded`에서 먼저 최종 높이를 계산하고, `dragTranslation` 리셋 전에 detent를 즉시 설정한 뒤 단일 `withAnimation`으로만 전환. 또는 `adjustedHeight` 계산 시 `.animation()` modifier에 `value:` 파라미터를 붙여 detent 변경에만 반응하도록 제한.
- 핵심: **detent 전환에만 1회 spring 적용, dragTranslation 리셋 시에는 애니메이션 없음.**

### 구체적 방향:
- `@GestureState`를 `@State`로 변경하여 리셋 타이밍을 직접 제어
- `.onEnded`에서: (1) target detent 계산 (2) `withAnimation(snapSpring) { detent = target; dragOffset = 0 }` 단일 블록으로 처리
- `adjustedHeight` 계산에 `.animation(nil)` 중복 방지

---

## Fix 2: 검색 바 정리 — 바만 남기기

In `Features/Home/UnfadingHomeView.swift`:

### 제거할 것:
1. **"언페이딩" + "우리의 흐려지지 않는 추억"** 텍스트 (topHeader 내 VStack, 약 line 382-387)
2. **TimeFilter 전체** — `enum TimeFilter`, 관련 `@State`, `ScrollView(.horizontal)` 필터 버튼 전부 (약 line 14-60, 449-475)
3. **현재 위치 버튼** topHeader 우측 상단에서 제거 (약 line 392-410)

### 남길 것:
- 검색 바 TextField만 (`HStack` with magnifying glass + TextField + clear button)
- 검색 바 패딩/배경 유지

### topHeader를 간소화:
```swift
private var topHeader: some View {
    // 검색 바만 남김
    HStack(spacing: 10) {
        Image(systemName: "magnifyingglass") ...
        TextField("데이트, 추억 검색", ...) ...
        // clear button ...
    }
    .padding(...)
    .background(...)
}
```

---

## Fix 3: 위치/나침반 버튼 — 검색 바 하단 우측 세로 배열

In `Features/Home/UnfadingHomeView.swift`:

### 추가할 것:
검색 바 아래, 지도 위에 오버레이로 배치. **우측 세로 배열, 작은 크기 (36pt 정도).**

```swift
// 검색 바 하단 우측에 세로 배열
VStack(spacing: 8) {
    // 현재 위치 이동
    Button { handleCurrentLocationTap() } label: {
        Image(systemName: "location.fill")
            .font(.caption)
            .frame(width: 36, height: 36)
    }
    .accessibilityLabel("현재 위치로 이동")

    // 방향 초기화 (북쪽 정렬)
    Button { resetMapHeading() } label: {
        Image(systemName: "location.north")
            .font(.caption)
            .frame(width: 36, height: 36)
    }
    .accessibilityLabel("지도 방향 초기화")
}
// 배경: UnfadingTheme.cardBackground, 둥근 모서리
// 위치: 검색 바 바로 아래 trailing에 padding
```

`resetMapHeading()`은 `cameraRegion`의 heading을 0으로 리셋하는 함수. 없으면 추가.

---

## Fix 4: 앱 시작 시 위치 권한 즉시 요청

In `App/UnfadingApp.swift`:
- `.task` 또는 `.onAppear`에서 `locationPermissionStore.requestPermission()` 호출
- `LocationPermissionStore`의 lazy init은 유지하되, 앱 시작 시 즉시 매니저 생성 + 권한 요청

In `Shared/LocationPermissionStore.swift`:
- `requestPermission()` 메서드가 없으면 추가: `CLLocationManager` 즉시 생성 + `requestWhenInUseAuthorization()` 호출

**주의:** 이전 금지 규칙 "앱 시작 시 위치 권한 요청 금지"를 명시적으로 해제. 사용자 요청에 의한 정책 변경.

---

## Files to modify

| File | Action |
|---|---|
| `Features/Home/MainBottomSheet.swift` | MODIFY — 애니메이션 이중 실행 제거 |
| `Features/Home/UnfadingHomeView.swift` | MODIFY — topHeader 간소화, TimeFilter 제거, 위치 버튼 재배치 |
| `App/UnfadingApp.swift` | MODIFY — 앱 시작 시 위치 권한 요청 |
| `Shared/LocationPermissionStore.swift` | MODIFY — requestPermission() 추가 (필요 시) |

---

## Constraints

- Run `xcodegen generate && xcodebuild -project Unfading.xcodeproj -scheme Unfading -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/unfading_build test`
- All tests must pass (≥79).
- All new UI text in Korean.
- 44pt minimum touch targets (위치/나침반 버튼은 36pt 시각 크기이나 hit area는 44pt 유지: `.frame(minWidth: 44, minHeight: 44)` + `.contentShape(Rectangle())`)
- UnfadingTheme colors only.
- `TimeFilter` 관련 테스트가 있으면 해당 테스트도 제거/수정.
