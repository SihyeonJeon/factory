# round_groups_r1 — Groups + ActiveGroupStore + onboarding

**Stage:** coding_1st
**Scope:** Replace placeholder GroupStore with Supabase-backed repository + activeGroup routing + onboarding for zero-group users.

## Acceptance
- DBModels (DBProfile/DBGroup/DBGroupMember) Codable w/ snake_case keys.
- SupabaseGroupRepository: fetchUserGroups / fetchMembers / createGroup / joinGroup / rotateInviteCode (RPCs from R15).
- GroupStore: bootstrap, create, join, rotate; @Published groups/activeGroupId/members/state.
- GroupOnboardingView: Korean create/join tabs with RPCs.
- GroupHubView uses real DBGroup + members; invite copy + rotate.
- MemoryMapApp branches: signedIn+!onboarded → Onboarding; signedIn+onboarded+no-group → GroupOnboarding; signedIn+has-group → RootTabView.
- UI-test stubs: -UI_TEST_GROUP_STUB injects fake group to skip Supabase calls.
- 111/111 tests pass (100 unit + 10 UITest + 1 new onboarding UITest).
