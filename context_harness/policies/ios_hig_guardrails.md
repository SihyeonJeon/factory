# iOS HIG Guardrails

This harness treats Apple Human Interface Guidelines as a release gate, not a style preference.

## Mandatory checks

- Use controls with hit targets of at least 44 pt by 44 pt.
- Respect safe areas on every screen and modal surface.
- Preserve native gestures unless a feature requires an exception.
- Support Dynamic Type, dark mode, contrast, and VoiceOver labels for core flows.
- Prefer native patterns over decorative custom UI when the custom version adds review risk.

## Review policy

- Product and planning roles can propose custom UI, but engineering must map the proposal to an HIG-safe implementation before coding starts.
- Vision QA must inspect screenshots for clipped content, low contrast, oversized floating controls, and gesture-hostile overlays.
- Code QA must reject hard-coded layout values that bypass safe areas or create undersized interactive targets.
- Any unresolved HIG failure blocks release readiness.

## App Store rejection prevention

- Do not ship AI-generated UI without an explicit HIG audit trail in `context_harness/reports/`.
- Keep acceptance criteria tied to user tasks, not only visual novelty.
- Avoid deceptive controls, hidden pricing, or fake system affordances.
- Treat screenshots, test logs, and accessibility notes as release evidence.

