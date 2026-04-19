# Remediation Round 9 — Sprint 6 HIG + Visual QA Blockers

**Date:** 2026-04-13
**Source:** hig_guardian + visual_qa (2 blockers + 3 warnings)
**Goal:** Fix all 5 items. All 69 tests must remain green.

---

## Fix B1: Hardcoded 52pt font on year display (YearEndReportView.swift)

### Problem
`.font(.system(size: 52, ...))` at line 18 — Dynamic Type users get no scaling.

### Implementation
- Add `@ScaledMetric private var yearFontSize: CGFloat = 52` to the view struct
- Replace `.font(.system(size: 52, weight: .bold, design: .rounded))` with `.font(.system(size: yearFontSize, weight: .bold, design: .rounded))`

---

## Fix B2: Remove member button tap target + confirmation (GroupHubView.swift)

### Problem
"Remove" member button at line ~140 has ~17pt tap area and fires destructive action with no confirmation.

### Implementation
- Add `.frame(minHeight: 44)` on the Remove button
- Add `@State private var memberToRemove: UUID?` to the view
- Instead of directly calling `groupStore.removeMember()`, set `memberToRemove = memberID`
- Add `.confirmationDialog("Remove Member?", isPresented: Binding, presenting: memberToRemove)` with "Remove" (destructive) and "Cancel" actions

---

## Fix W1: Theme button accessibilityHint (DiaryCoverCustomizationView.swift)

### Problem
Theme buttons at line ~51 missing accessibilityHint.

### Implementation
- Add `.accessibilityHint("Double tap to apply this theme")` on each theme button

---

## Fix W2: Decorative color bar exposed to VoiceOver (GroupHubView.swift)

### Problem
Decorative `RoundedRectangle` color bar at line ~87 is exposed to VoiceOver.

### Implementation
- Add `.accessibilityHidden(true)` to the decorative color bar

---

## Fix W3: Invite code missing accessibilityLabel (GroupHubView.swift)

### Problem
`Text(invitation.code)` at line ~281 has no context for VoiceOver users.

### Implementation
- Add `.accessibilityLabel("Invite code: \(invitation.code)")` on the code Text

---

## Constraints

- Run `xcodegen generate && xcodebuild -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/memorymap_build test` after all edits.
- All 69 tests must pass.
