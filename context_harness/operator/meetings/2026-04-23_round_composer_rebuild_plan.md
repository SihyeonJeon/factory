---
round: round_composer_rebuild_r1
stage: coding_1st
status: draft
participants: [codex]
decision_id: r31-composer-rebuild-plan
contract_hash: b59ef305e8a46e2faf24b37f895c075963a76210823ffaef6c8f449e42b0eeef
---

## Context
- Source of truth: `contracts/round_composer_rebuild_r1/spec.md` and design handoff Composer section.
- Current implementation was a section/card composer with note-or-photo save gating.
- R31 requires prototype order, place confirmation gate, event binding, participants, emotions, and cost persistence.
- Existing R-feedback1 photo seed and `PlacePickerSheet` paths must remain.

## Proposal
- Expand `MemoryComposerState` with `PlaceState`, `EventBinding`, wheel time fields, participants, cost, and photo seed notice.
- Replace the sheet body with custom Composer header and prototype-ordered rows.
- Add small reusable components for field rows, mini buttons, source chips, participant chips, wheel picker, and event sheet.
- Extend `DBMemoryInsert`/`DBMemory` for `event_id`, `participant_user_ids`, and `cost`.

## Questions
- No product ambiguity requiring human decision. Empty note/photos/emotions/cost remains allowed once place is confirmed, per acceptance 11.

## Counter / Review
- Self-review only for implementation planning; separate verifier still required by Author ≠ Verifier.

## Convergence
- Proceed with a single implementation pass because all changed files are in the R31 composer/model/test surface.

## Decision
- Adopt place confirmation as the only save gate besides upload state.
- Treat unopened event field as `.none`; only explicit create or existing selection produces `event_id`.
- In general groups, default participant selection to all loaded group members; in couple mode, omit participant UI and save an empty participant array.

## Challenge Section
- Objection: Keeping the old NavigationStack toolbar would satisfy existing UITests but miss the prototype header. Rejected; use custom header and update UITest lookup.
- Risk: `CLLocationManager().location` can be nil on simulator. Mitigation: current-location MiniButton falls back to existing selected coordinate; explicit confirm button remains deterministic.
- Risk: DB rows without new columns can fail decode if modeled as required. Mitigation: `DBMemory` custom decoder defaults missing `participant_user_ids`, `categories`, `emotions`, and reaction count.
- Rejected alternative: Make event auto-fetch happen during Composer open. Rejected because acceptance places event fetch inside `EventFieldSheet`, reducing network work until the field is used.
