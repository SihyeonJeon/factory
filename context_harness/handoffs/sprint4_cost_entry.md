# Sprint 4 — Optional Cost Entry

**Date:** 2026-04-13
**Prerequisite:** Sprint 3 + Remediation r6 green (56/56 tests)
**Goal:** Add optional cost entry to memory records. All tests green after.

---

## Feature 1: Cost Entry in Memory Records

### Acceptance criteria
- Cost entry must remain optional in all modes.
- Users can attach a cost amount and optional label to a memory record.
- Cost data is stored on `DomainMemory` and displayed in `MemoryDetailView`.

### Implementation spec

1. **`Shared/Domain/MemoryDomain.swift`** modification
   - Add `cost: Double?` and `costLabel: String?` fields to `DomainMemory`
   - Default both to `nil` in the initializer
   - Keep backward-compatible: existing code that creates `DomainMemory` without cost fields must still compile

2. **`Features/Home/MemoryComposerSheet.swift`** modification
   - Add an optional "Cost" section after "Mood":
     ```swift
     Section("Cost (optional)") {
         Toggle("Add cost", isOn: $hasCost)
         if hasCost {
             HStack {
                 TextField("Amount", value: $costAmount, format: .number)
                     .keyboardType(.decimalPad)
                     .frame(minHeight: 44)
                 TextField("Label (e.g. dinner, taxi)", text: $costLabel)
                     .frame(minHeight: 44)
             }
         }
     }
     ```
   - Add `@State private var hasCost = false`
   - Add `@State private var costAmount: Double? = nil`
   - Add `@State private var costLabel = ""`
   - Pass `cost` and `costLabel` through `MemoryComposerDraft` to `DomainMemory`

3. **`MemoryComposerDraft`** modification (in MemoryComposerSheet.swift)
   - Add `var cost: Double? = nil` and `var costLabel: String? = nil`
   - Pass to `DomainMemory(... cost: cost, costLabel: costLabel)` in `save()`

4. **`Features/Home/MemoryDetailView.swift`** modification
   - If `memory.cost != nil`, show a row below the note:
     ```swift
     if let cost = memory.cost {
         LabeledContent(memory.costLabel ?? "Cost") {
             Text(cost, format: .currency(code: "KRW"))
         }
     }
     ```

### Tests to add
- `testMemoryWithCostStoresAmount` — create DomainMemory with cost=15000, assert cost is preserved
- `testMemoryWithoutCostDefaultsToNil` — create DomainMemory without cost params, assert cost is nil
- `testComposerSaveWithCostPreservesCost` — save via MemoryComposerDraft with cost, verify stored memory has cost

---

## Constraints

- Run `xcodegen generate && xcodebuild -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/memorymap_build test` after all edits.
- All 56 existing tests must pass. New tests bring total to ~59.
- Cost fields must be optional everywhere — never force unwrap or require cost.
- Use `format: .currency(code: "KRW")` for display (Korean Won).
