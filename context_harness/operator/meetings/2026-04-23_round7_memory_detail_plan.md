---
round: round_memory_detail_r1
stage: operator_amendment
status: decided
participants: [claude_code, codex]
decision_id: 20260423-round7-memory-detail
contract_hash: none
created_at: 2026-04-23T02:30:00Z
codex_session_id: 019db43d-746e-73b3-b33c-5dda3770df91
---

# R7 — Memory Detail Screen

## Scope
New `MemoryDetailView` accessed from Map pin selection or Summary card tap. Per deepsight: photo carousel, location card, time + people + mood sections, note body, member contribution cards.

## Deliverables
- `workspace/ios/Features/Detail/MemoryDetailView.swift` (new)
- `workspace/ios/Shared/SampleModels.swift` extended with `SampleMemoryDetail` + contributions (will whitelist SampleModels this round)
- `MemorySummaryCard.swift` gets an optional "상세 보기" NavigationLink → MemoryDetailView
- `MemoryMapHomeView.swift` uses NavigationStack to push detail on selection pin tap when selection is already present
- Tests: detail view builds with mock data; contribution list renders

## Reuse
- UnfadingTheme/Localized/CardBackground/Button

## Challenge Section
### Objection
Whitelisting SampleModels for first time — historical data source. Justified: detail screen needs fuller sample structure than R2 minimal.
### Risk
NavigationLink inside a Map-hosted selection may interact weirdly with the bottom sheet. Mitigation: push detail from the sheet's "상세 보기" button, not from tap-on-pin directly.
### Rejected alt
Inline expansion (no navigation). Rejected: deepsight shows a dedicated detail screen with full metadata.

## Decision
PROCEED: new MemoryDetailView + SampleMemoryDetail + MemorySummaryCard onDetailTap + NavigationStack in Map. Codex dispatched for impl; operator does not edit Swift (v5.7).
