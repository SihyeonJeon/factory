---
round: round_rewind_stories_r1
stage: implementation
status: decided
participants: [claude_code, codex]
decision_id: 20260423-r34-rewind-stories
contract_hash: none
created_at: 2026-04-23T00:00:00Z
---

# R34 Rewind Stories

## Context
- Contract source: `context_harness/operator/contracts/round_rewind_stories_r1/spec.md`.
- Design source: `docs/design-docs/unfading_ref/design_handoff_unfading/README.md` section 8 "Rewind".
- Prototype source: `prototype/Unfading Prototype.html` `RewindScreen`.

## Proposal
- Replace the old scroll/navigation Rewind feed with a full-screen `TabView(.page)` Stories deck.
- Build six cards: cover, TOP 3 places, first visits, photo-heavy day, emotion cloud, and time together.
- Add `RewindData.sample(for:)` using existing sample memories; real Supabase query remains deferred to R38.
- Wire home curation to `fullScreenCover`, with close returning the home sheet snap to `default`.

## Questions
- None for this implementation slice.

## Counter / Review
- Risk: auto-advance can conflict with accessibility motion preferences.
- Mitigation: timer advances only when `accessibilityReduceMotion == false`.

## Convergence
- Proceed with local sample aggregation and stable UI test identifiers.

## Decision
- Implement R34 as scoped by acceptance 1-7.

## Challenge Section
- Rejected alternative: keep the previous `NavigationStack` list of `RewindMomentCard` rows. It does not satisfy the full-screen Stories contract or custom progress tick bar.
- Deferred: live Supabase query for monthly/yearly rewind data belongs to R38.
