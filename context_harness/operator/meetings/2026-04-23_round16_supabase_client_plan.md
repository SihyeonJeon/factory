---
round: round_supabase_client_r1
stage: coding_1st
status: decided
participants: [claude_code, codex]
decision_id: 20260423-r16-supabase-client
contract_hash: none
created_at: 2026-04-23T10:50:00Z
codex_session_id: fresh
---
# R16 Supabase Swift SDK + client singleton — plan & outcome

## Context
R15 finished DB side. R16 is the Swift client: SPM dep + Info.plist config + singleton facade.

## Plan
1. Add SPM `supabase-swift` @ 2.30.0 in `project.yml.packages`.
2. Depend MemoryMap target on `Supabase` product.
3. Bake `SupabaseURL` / `SupabasePublishableKey` into Info.plist (publishable key is client-safe).
4. `Shared/SupabaseService.swift`: singleton, `url`/`publishableKey` service-level, facade for `auth/database/storage/realtime`.
5. 2 unit tests asserting bundle-backed config.

## Challenge Section
### Objection
Keep secrets out of Info.plist? Rejected: publishable key is explicitly client-safe per Supabase docs and ships with every Swift SDK example. Distinct from service role key (stays server-only).

### Risk
SDK surface drift — `client.database` was a v1 property that became internal in v2. Worked around via `client.schema("public")` returning `PostgrestClient`.

### Build issue
Codex sandbox lacks network → SPM fetch fails. Operator ran `xcodebuild test` outside sandbox; 99/99 PASS (92 unit + 7 UITest).

### Blocker fix (round internal)
Initial SupabaseServiceTests read `service.client.supabaseURL` which is internal in the Supabase module. Exposed `SupabaseService.url` / `.publishableKey` service-level properties; test now passes.

## Outcome
- 99/99 tests pass.
- xcresult: `workspace/ios/.deriveddata/r16/Test-R16.xcresult`.
- No runtime Supabase calls yet (R17 wires auth, which exercises the network path).
