# Remediation Round 8 — Sprint 5 HIG + Visual QA Blockers

**Date:** 2026-04-13
**Source:** hig_guardian + visual_qa (2 identical blockers + 4 advisories)
**Goal:** Fix 2 blockers + 4 advisories. All 64 tests must remain green.

---

## Fix B1: Hardcoded 42pt font on invite code (GroupHubView.swift)

### Problem
`GroupHubView.swift:265` uses `.font(.system(size: 42, ...))` which freezes the invite code display for all Dynamic Type users.

### Implementation
- Replace `.font(.system(size: 42, design: .monospaced).bold())` with `.font(.largeTitle.monospaced().bold())`
- This respects Dynamic Type scaling automatically

---

## Fix B2: Zero-memory year empty state (YearlyRecapView.swift)

### Problem
When a year has zero memories, the view silently renders all-zero stat cards with no meaningful content.

### Implementation
- Add a guard at the top of the view body:
  ```swift
  if recap.totalMemories == 0 {
      ContentUnavailableView(
          "No memories in \(selectedYear)",
          systemImage: "calendar.badge.exclamationmark",
          description: Text("Record some memories to see your yearly recap here.")
      )
  } else {
      // existing stat grid + bar chart
  }
  ```

---

## Advisory A1: Note truncation in GroupTimelineView

### Problem
`GroupTimelineView.swift:108` uses `.lineLimit(1)` which silently truncates notes.

### Implementation
- Change `.lineLimit(1)` to `.lineLimit(2)` for note preview

---

## Advisory A2: RewindMomentCard VoiceOver grouping

### Problem
`RewindMomentCard.swift:20-31` has no VoiceOver grouping on card info/metadata.

### Implementation
- Add `.accessibilityElement(children: .combine)` on the card's outer container

---

## Advisory A3: GroupHubView swipe-to-delete accessible alternative

### Problem
`GroupHubView.swift:18` has swipe-to-delete but no accessible alternative for users who can't swipe.

### Implementation
- Add `EditButton()` in the toolbar for the group list section

---

## Advisory A4: RewindSettingsView per-memory toggle grouping

### Problem
`RewindSettingsView.swift:44-46` per-memory toggle VStack not grouped for VoiceOver.

### Implementation
- Add `.accessibilityElement(children: .combine)` on each toggle row VStack

---

## Constraints

- Run `xcodegen generate && xcodebuild -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/memorymap_build test` after all edits.
- All 64 tests must pass.
