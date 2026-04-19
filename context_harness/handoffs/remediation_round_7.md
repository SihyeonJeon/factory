# Remediation Round 7 — Sprint 4 HIG + Visual QA Blockers

**Date:** 2026-04-13
**Source:** hig_guardian + visual_qa (4 identical blockers)
**Goal:** Fix 4 blockers. All 59 tests must remain green.

---

## Fix B1: Cost row mis-grouped inside Note section (MemoryDetailView.swift)

### Problem
`LabeledContent` for cost (lines ~80-84) is nested inside the Note `VStack`. VoiceOver narrates it as note content.

### Implementation
- Move the `if let cost = currentMemory.cost { ... }` block OUT of the Note `VStack(alignment: .leading, spacing: 8)` 
- Place it at the outer `VStack(alignment: .leading, spacing: 20)` level, as its own section between Note and Emotions
- Add `.accessibilityLabel` on the cost `LabeledContent`

---

## Fix B2: Two TextFields in HStack → separate Form rows (MemoryComposerSheet.swift)

### Problem
Side-by-side `HStack` with two TextFields clips at Dynamic Type ≥ `.xLarge` and VoiceOver treats both as one cell.

### Implementation
- Replace the `HStack { TextField("Amount"...) TextField("Label"...) }` with two separate rows:
  ```swift
  TextField("Amount", value: $costAmount, format: .currency(code: "KRW"))
      .keyboardType(.decimalPad)
      .frame(minHeight: 44)
      .accessibilityLabel("비용 금액")
  
  TextField("Label (e.g. dinner, taxi)", text: $costLabel)
      .frame(minHeight: 44)
      .accessibilityLabel("비용 항목")
  ```

---

## Fix B3: .number → .currency format (MemoryComposerSheet.swift)

### Problem
Amount field uses `format: .number` — user types 50000 but sees ₩50,000 only after save.

### Implementation
- Change `format: .number` → `format: .currency(code: "KRW")` on the amount TextField
- (Already included in B2 fix above)

---

## Fix B4: Missing .accessibilityLabel on cost TextFields (MemoryComposerSheet.swift)

### Problem
Placeholders disappear after typing; VoiceOver falls back to "text field".

### Implementation
- Add `.accessibilityLabel("비용 금액")` on amount field
- Add `.accessibilityLabel("비용 항목")` on label field
- (Already included in B2 fix above)

---

## Constraints

- Run `xcodegen generate && xcodebuild -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/memorymap_build test` after all edits.
- All 59 tests must pass.
- Only touch `MemoryDetailView.swift` and `MemoryComposerSheet.swift`.
