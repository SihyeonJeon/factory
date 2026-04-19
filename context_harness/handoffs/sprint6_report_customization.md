# Sprint 6 — Year-End Memory Report & Diary Cover Customization

**Date:** 2026-04-13
**Prerequisite:** Sprint 5 + Remediation r8 green (64/64 tests)
**Goal:** 2 nice-to-have features. All tests green after.

---

## Feature 1: Auto-Generated Year-End Memory Report

### Acceptance criteria (from "Nice to have")
- Auto-generated year-end memory reports showing a shareable summary of the year's memories.

### Implementation spec

1. **`Shared/Domain/YearlyRecap.swift`** modification
   - Add computed property `narrativeSummary: String` that generates a human-readable paragraph:
     ```swift
     var narrativeSummary: String {
         var lines: [String] = []
         lines.append("📍 \(year)년 한 해 동안 \(uniquePlaces)곳에서 \(totalMemories)개의 추억을 기록했습니다.")
         if let topEmotion {
             lines.append("가장 많이 느낀 감정은 \(topEmotion.title)이었습니다.")
         }
         if totalCost > 0 {
             lines.append("총 \(totalCost.formatted(.currency(code: "KRW")))을 함께 사용했습니다.")
         }
         let busiestMonth = monthlyBreakdown.max(by: { $0.value < $1.value })
         if let busiestMonth, busiestMonth.value > 0 {
             let monthName = Calendar.current.monthSymbols[busiestMonth.key - 1]
             lines.append("가장 활발했던 달은 \(monthName) (\(busiestMonth.value)개)입니다.")
         }
         return lines.joined(separator: "\n")
     }
     ```

2. **`Features/Rewind/YearEndReportView.swift`** (NEW)
   - Full-screen shareable report card view
   - Shows:
     - Large year title with gradient background
     - Narrative summary text from `YearlyRecap.narrativeSummary`
     - Stats grid (reuse StatCard pattern from YearlyRecapView)
     - Monthly bar chart (compact version)
   - `ShareLink` at bottom to share the narrative summary as text
   - Accessible: `.accessibilityElement(children: .combine)` on the report card

3. **`Features/Rewind/YearlyRecapView.swift`** modification
   - Add a `NavigationLink` at the bottom of the stats section:
     ```swift
     NavigationLink {
         YearEndReportView(recap: recap)
     } label: {
         Label("View Full Report", systemImage: "doc.text")
             .frame(minHeight: 44)
     }
     ```

---

## Feature 2: Diary Cover Customization

### Acceptance criteria (from "Nice to have")
- Diary cover customization with selectable themes.

### Implementation spec

1. **`Shared/Domain/DiaryCoverTheme.swift`** (NEW)
   ```swift
   enum DiaryCoverTheme: String, Codable, CaseIterable, Identifiable {
       case classic
       case sunset
       case ocean
       case forest
       case lavender
       case midnight

       var id: String { rawValue }

       var displayName: String {
           switch self {
           case .classic: return "Classic"
           case .sunset: return "Sunset"
           case .ocean: return "Ocean"
           case .forest: return "Forest"
           case .lavender: return "Lavender"
           case .midnight: return "Midnight"
           }
       }

       var gradient: LinearGradient {
           switch self {
           case .classic: return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
           case .sunset: return LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
           case .ocean: return LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom)
           case .forest: return LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
           case .lavender: return LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
           case .midnight: return LinearGradient(colors: [.indigo, .black], startPoint: .top, endPoint: .bottom)
           }
       }
   }
   ```

2. **`Shared/Domain/GroupStore.swift`** modification
   - Add `@Published var groupThemes: [UUID: DiaryCoverTheme] = [:]`
   - Add `func setTheme(_ theme: DiaryCoverTheme, for groupID: UUID)`
   - Add `func theme(for groupID: UUID) -> DiaryCoverTheme` (defaults to `.classic`)

3. **`Features/Groups/DiaryCoverCustomizationView.swift`** (NEW)
   - Grid of theme swatches (3 columns)
   - Each swatch: rounded rectangle with the gradient + theme name below
   - Selected theme shows checkmark overlay
   - Tap applies theme via `groupStore.setTheme()`
   - Preview of how the cover looks with group name overlaid on gradient

4. **`Features/Groups/GroupHubView.swift`** modification
   - Add "Customize Cover" `NavigationLink` with `systemImage: "paintbrush"` for each group
   - Links to `DiaryCoverCustomizationView(groupID: group.id)`
   - Apply group's theme gradient as the group row's leading accent

### Tests to add
- `testYearlyRecapNarrativeSummary` — verify narrativeSummary contains year, place count, memory count
- `testYearEndReportShareableText` — verify narrative summary is non-empty for non-zero recap
- `testDiaryCoverThemeDefaultsToClassic` — verify GroupStore returns .classic for unset group
- `testSetDiaryCoverTheme` — set theme to .sunset, verify GroupStore returns .sunset
- `testAllDiaryCoverThemesHaveGradient` — verify all cases produce non-nil gradient

---

## Constraints

- Run `xcodegen generate && xcodebuild -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/memorymap_build test` after all edits.
- All 64 existing tests must pass. New tests bring total to ~69.
