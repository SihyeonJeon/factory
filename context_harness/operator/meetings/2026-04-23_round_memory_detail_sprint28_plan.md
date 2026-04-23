---
round: round_memory_detail_sprint28_r1
stage: coding_1st
status: decided
participants: [codex]
decision_id: r32-memory-detail-plan
contract_hash: 50cb4996de6c3b627e95c66263e59a9e4ef4275a80d29a10613dd279a8db7036
---

## Context
- Source of truth: `contracts/round_memory_detail_sprint28_r1/spec.md`.
- Design input: README section 5 "Memory Detail" and prototype `detail.jsx`.
- Current implementation was SampleMemoryPin-only and moved across all sample pins.
- Target state is DBMemory-driven detail with same-event carousel, Sprint 28 section order, and inline "한 줄 더 쓰기".

## Proposal
- Rewrite `MemoryDetailView` around `DBMemory`, `eventMemories`, `participants`, and `GroupMode`.
- Add Detail components for similar places, same-event mini gallery, and general-group participants.
- Keep the old `MemoryDetailView(pin:)` adapter only for current sample-map navigation.
- Keep "한 줄 더 쓰기" as client `@State` only in this round.

## Questions
- Lock file was not present in `context_harness/operator/locks/` during this fresh session.
- No DB table should be introduced in R32 because spec defers persistence to R38.

## Counter / Review
- Risk: the current Home route still starts from sample pins. Mitigation: preserve a sample adapter while making the primary Detail API DBMemory-based.
- Risk: weather is not a DB field. Mitigation: use sample display copy and record API/data persistence as out of scope.
- Risk: self-verification is limited because this is a single-operator implementation session. Mitigation: keep evidence factual and avoid verdict language.

## Convergence
- Implement the DBMemory surface now.
- Avoid schema changes and repository writes for extra lines.
- Tests cover event scoping, participant mode gating, and one-line submission policy.

## Decision
Proceed with R32 implementation within the whitelist above.

## Challenge Section
- Challenge: adding a local-only one-line input can look like persistence to users.
- Response: UI disables after one submission only for the current view state and evidence notes explicitly mark DB persistence as R38 deferred.
