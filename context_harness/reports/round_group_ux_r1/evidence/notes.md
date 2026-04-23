# R25 Group UX Evidence Notes

## Root Cause

Group creation previously surfaced only `잠시 후 다시 시도해주세요.` in the client. The immediate production root cause was a server-side Supabase RPC failure: `gen_random_bytes` was not resolvable under the RPC search path. The server migration has been applied by the operator before this client round.

## Client Gap

The iOS onboarding flow collapsed all create failures into `UnfadingLocalized.Groups.actionFailed`, which prevented operators from seeing the real failure class during debugging. Join failures also mapped to a generic invalid-code message after local pre-checks.

## Client Actions

- Added `group_members.nickname` decoding to `DBGroupMember`.
- Added `DBGroupMemberWithProfile` for `group_members` rows joined with `profiles(*)`.
- Updated group repository calls for the new `create_group_with_membership` and `join_group_by_code` `p_nickname` parameter.
- Added repository methods for `update_group_name` and `set_group_nickname`.
- Updated `GroupStore` to load member rows with nicknames, expose `memberProfiles`, prefer nickname in display names, and update local state after rename/nickname RPC success.
- Added optional nickname fields to group create/join onboarding.
- Added group-name editing for owners and nickname editing for current group members in Group Hub.
- Updated onboarding RPC error handling to append a truncated actual error suffix while keeping the existing Korean fallback.

## Server Action Already Applied

- Supabase migration fixed the RPC `gen_random_bytes` search_path issue.
- Supabase migration added `public.group_members.nickname`.
- Supabase migration added/updated the RPCs required by this client round.

## Local Verification Attempt

- `xcodegen generate` completed and recreated `workspace/ios/MemoryMap.xcodeproj`.
- The requested `xcodebuild test` command stopped before build/test execution during SPM package resolution. The sandbox could not resolve `github.com`, so dependencies such as `supabase-swift`, `swift-clocks`, `swift-crypto`, and `swift-http-types` could not be cloned into `.deriveddata/r25/SourcePackages`.
- `.deriveddata/r25/Test-R25.xcresult` was created with xcodebuild error 74, but no executed test count was available.
