# round_supabase_client_r1 — Supabase Swift SDK + client singleton

**Round ID:** round_supabase_client_r1
**Stage:** coding_1st (Codex implementation under v5.7 Swift delegation)
**Owner-operator:** claude_code (dispatches)
**Implementer:** codex (exec)
**Verifier:** claude_code (evidence review + build verification outside sandbox)

## Objective
Wire `supabase-swift` SDK into the iOS app so R17+ can use `SupabaseService.shared.{auth,database,storage,realtime}`.

## Acceptance
- SPM package `supabase-swift` @ 2.30+ declared in project.yml and resolved.
- `SupabaseService` singleton reads `SupabaseURL` + `SupabasePublishableKey` from Info.plist.
- Unit tests: `SupabaseServiceTests.testSharedClientAvailable`, `testConfigFromBundleReadsInfoPlist`.
- `xcodebuild test` passes all prior tests + 2 new (total 99: 92 unit + 7 UITest).
- No data calls yet — smoke-level wiring only.
