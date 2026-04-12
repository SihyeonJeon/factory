# Design Direction

## Overall feeling

The product should feel intimate, reflective, and warm, while still clearly belonging to modern iOS. It should never feel noisy, gimmicky, or like an AI-generated placeholder interface.

The main map screen should feel closer to an iPhone-native maps product than to a social feed. The bottom sheet should feel as fluid and trustworthy as the iPhone Photos app or a best-in-class map result panel.

## Reference products

- Borrow the emotional clarity of a private diary.
- Borrow the spatial confidence and calm hierarchy of a strong native map experience.
- Borrow the bottom-sheet confidence of Naver Map or Google Maps result panels.
- Borrow the content grouping clarity of the iPhone Photos app when listing photos under a date or event.
- Borrow the polish level expected from top-tier iOS productivity or memory products.

## Visual rules

- Typography: clear hierarchy between titles, place names, body copy, and metadata.
- Color: warm, memory-oriented, and expressive without losing readability or dark-mode quality.
- Motion: restrained and purposeful. Cluster zoom, bottom-sheet snapping, filter changes, and rewind reveal should feel smooth, not flashy.
- Density: avoid cramped cards, oversized floating controls, and cluttered overlays.
- Emphasize map pins, date headers, memory cards, event summaries, group headers, and emotion tags.
- Avoid overdecorated chrome, fake system elements, excessive gradients, or novelty-first UI.

## Native expectations

- Preserve safe areas, native gestures, and predictable navigation.
- Prefer native patterns when custom behavior would increase review risk.
- Maintain obviously iOS-like spacing, hit targets, and interaction rhythm.
- If a screen still looks like an unfinished AI draft, it must fail review even if technically functional.

## Mode-aware presentation

- `couple` mode may use more intimate wording, anniversary-oriented cues, softer memory curation labels, and more romantic summary language.
- `general_group` mode should use neutral group-oriented wording, group travel or meetup framing, and shared-history cues.
- The mode difference should be obvious in copy, keywords, and curation emphasis, but the underlying navigation and interaction model must stay consistent.

## Main screen interaction direction

- The global layout should behave as four layers:
  - full-screen map background
  - floating header with search and group selector
  - floating add-memory action
  - foreground animated bottom sheet
- The bottom sheet should support three snap points:
  - collapsed summary state
  - default half-open browsing state
  - expanded gallery state
- Default bottom-sheet content should show curated and recommended memory groupings.
- Curation should adapt to available memories rather than follow a rigid fixed section order.
- The curation logic may borrow from the iPhone Photos app approach:
  - resurfacing meaningful recency
  - anniversary or rewind moments
  - place-based bundles
  - trip or event-based bundles
  - socially meaningful groupings when multiple members contributed
- When a marker or cluster is selected, the sheet should automatically rise and switch to filtered content for that selected geographic context.
- The bottom sheet should function as the primary gallery browser, not just as a preview strip.
- Tapping a memory card should open a memory detail page, and that detail page should support moving to adjacent related memories when it improves browsing efficiency.
