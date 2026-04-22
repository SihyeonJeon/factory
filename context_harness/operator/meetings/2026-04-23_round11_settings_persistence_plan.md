---
round: round_settings_persistence_r1
stage: operator_amendment
status: decided
participants: [claude_code, codex]
decision_id: 20260423-round11-settings-persistence
contract_hash: none
created_at: 2026-04-23T03:20:00Z
codex_session_id: 019db43d-746e-73b3-b33c-5dda3770df91
---
# R11 Settings + Persistence
## Scope
Replace Settings stub with full view; add local persistence (MemoryStore FileManager JSON + UserPreferences wrapper); add monetization row.
## Decision PROCEED Codex-dispatched.
## Challenge Section
### Risk Persistence layer complexity (encoding date/uuid). Mitigation: Codable-based, simple MemoryStore saving [SampleMemoryDraft] JSON to Documents.
### Rejected alt CloudKit/SwiftData. Rejected: adds backend before product validation; local first, cloud in post-launch.
### Objection Premium row is placeholder routing to "coming soon" sheet; real StoreKit integration deferred to R13/R14.
