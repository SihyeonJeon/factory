# r13 spec base e10f55e
## Deliverables
1. Audit doc at docs/design-docs/a11y-audit-2026.md listing findings per screen (Map/Detail/Composer/Calendar/Rewind/GroupHub/Settings/Onboarding)
2. Fix gaps in touched view files:
   - Missing accessibilityLabel on interactive images/icons
   - Missing accessibilityHint where action non-obvious
   - accessibilitySortPriority to ensure logical VoiceOver order on complex screens (Detail, Composer)
   - accessibilityElement(children:.combine) for card-style groupings where sensible
   - @Environment(\.accessibilityReduceMotion) awareness for animations (UnfadingPrimaryButtonStyle, BottomSheet drag springs)
   - .dynamicTypeSize(...DynamicTypeSize.xxxLarge) set appropriate upper bound
3. New test file workspace/ios/Tests/AccessibilityAuditTests.swift — ≥ 3 tests validating key a11y contracts (Summary card announces as combined element, FAB has label AND hint, BottomSheet handle has a11y label)
4. Update UnfadingLocalized.Accessibility with any new hints
## Acceptance
- Audit doc exists with per-screen findings + fixes
- Tests ≥ 89
- Zero regressions
- Screenshot of Dynamic Type XXL active
