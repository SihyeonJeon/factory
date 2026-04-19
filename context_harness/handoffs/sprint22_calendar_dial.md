# Sprint 22 — 캘린더 다이얼 네비게이션 + 시간 다이얼

**Date:** 2026-04-14
**Source:** Human Feedback Round 3
**Goal:** 캘린더 좌우 스와이프 제거, 월/년 다이얼 피커 추가, 추억 만들기 시간도 다이얼

---

## Fix 1: 캘린더 네비게이션 변경

In `Features/Calendar/MonthlyCalendarGrid.swift`:

### 제거:
- `DragGesture` (좌우 스와이프로 월 이동) — 약 line 92-101

### 유지:
- 화살표 버튼 (chevron.left / chevron.right) — 이전/다음 달 이동

### 추가: 월/년 다이얼 피커
- 월 이름 텍스트(`Text(monthStart.formatted(...))`)를 **탭 가능**하게 변경
- 탭 시 `.sheet`로 다이얼 피커 표시:
  - `Picker` with `.pickerStyle(.wheel)` — "월" 선택 (1월~12월)
  - `Picker` with `.pickerStyle(.wheel)` — "년" 선택 (2020~현재연도+1)
  - "확인" 버튼으로 적용
- 한국어: "월 선택", "년 선택", "확인"

### 다이얼 피커 예시:
```swift
.sheet(isPresented: $showingMonthYearPicker) {
    VStack(spacing: 16) {
        Text("날짜 선택")
            .font(.system(.headline, design: .rounded))
        
        HStack {
            Picker("년", selection: $pickerYear) {
                ForEach(2020...(currentYear + 1), id: \.self) { year in
                    Text("\(year)년").tag(year)
                }
            }
            .pickerStyle(.wheel)
            
            Picker("월", selection: $pickerMonth) {
                ForEach(1...12, id: \.self) { month in
                    Text("\(month)월").tag(month)
                }
            }
            .pickerStyle(.wheel)
        }
        
        Button("확인") {
            applyPickedDate()
            showingMonthYearPicker = false
        }
        .frame(minHeight: 44)
    }
    .presentationDetents([.medium])
}
```

---

## Fix 2: 추억 만들기 시간 설정 — 다이얼

In `Features/Home/MemoryComposerSheet.swift`:

### 변경:
현재 시간 표시 (`LabeledContent("시간")` 약 line 145-148)를:
- `DatePicker` with `.datePickerStyle(.wheel)` + `.labelsHidden()` 로 변경
- 또는 시간을 탭하면 wheel picker sheet가 뜨도록
- 표시 컴포넌트: `.hourAndMinute`만

```swift
DatePicker("시간", selection: $capturedAt, displayedComponents: .hourAndMinute)
    .datePickerStyle(.wheel)
    .labelsHidden()
    .accessibilityLabel("추억 시간 설정")
```

---

## Files to modify

| File | Action |
|---|---|
| `Features/Calendar/MonthlyCalendarGrid.swift` | MODIFY — 스와이프 제거, 월/년 다이얼 피커 추가 |
| `Features/Home/MemoryComposerSheet.swift` | MODIFY — 시간 설정 wheel picker |

---

## Constraints

- Run `xcodegen generate && xcodebuild -project Unfading.xcodeproj -scheme Unfading -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/unfading_build test`
- All tests must pass (≥77).
- All new UI text in Korean.
- 44pt minimum touch targets.
- UnfadingTheme colors only.
- `.accessibilityLabel` on all interactive elements.
