# Factory Session Resume — 2026-04-23 (EoD)

**Single source of truth.** Two major production blocks this date:
- Block A (morning, 8h): R3–R14 local-only UI buildout to "deepsight surfaces complete"
- Block B (afternoon): R15–R24 real-cloud backend integration → actually launchable

---

## 0. Harness

Current: v5.7 (Swift delegation to Codex + multi-axis eval + vibe-coding regulation + CHANGELOG meeting-trail enforcement).
Temporary regulation (2026-04-23→25): Codex workload share raised; round artifacts can be bundled into Codex dispatches.

## 1. Block A rounds (R3–R14) — UI surfaces

| Round | Content | Tests |
|---|---|---:|
| R3–R14 | 5-tab nav + bottom-sheet map + composer + memory detail + calendar + rewind + group hub + settings + persistence + onboarding + a11y + XCUITest screenshots | 90 unit + 7 UITest |

(See commit history 43a7938..7530197 for per-round detail.)

## 2. Block B rounds (R15–R24) — Cloud integration

| Round | Contract id | Content | Tests | Commit |
|---|---|---|---:|---|
| R15 | round_supabase_schema_r1 | 8 SQL migrations: groups.cover_color_hex, subscriptions table, memories bucket lockdown (public→private + 25MB + mime allowlist), storage RLS policies, group helper RPCs, reaction-count trigger, group_members roster visibility, advisor fix | — | 8952087 |
| R16 | round_supabase_client_r1 | supabase-swift 2.30+ SPM; SupabaseService singleton; Info.plist URL+publishable key; 2 new unit tests | 99 | 06d9e2d |
| R17 | round_auth_r1 | email/password auth via Supabase Auth; AuthStore + AuthLandingView; MemoryMapApp root branching; UI-test stub flags | 104 | d4f06db |
| R18 | round_groups_r1 | DBProfile/DBGroup/DBGroupMember; SupabaseGroupRepository; GroupStore with bootstrap/create/join/rotate; GroupOnboardingView; GroupHubView DB-backed | 111 | fa6afef |
| R19 | round_memories_r1 | DBMemory/DBMemoryInsert; SupabaseMemoryRepository; MemoryStore CRUD + offline JSON cache + realtime postgres_changes subscription | 115 | 79fbd3d |
| R20 | round_photos_r1 | PhotoUploader actor (PHAsset → JPEG → Storage); RemoteImageView signed-URL AsyncImage; composer upload-first-then-insert with rollback | 120 | b464078 |
| R21 | round_profile_sync_r1 | profiles.preferences jsonb; ProfileRepository; UserPreferences bidirectional cloud sync (500ms debounced); profile section in Settings | 124 | 19eff1d |
| R22 | round_storekit_r1 | StoreKitConfiguration.storekit; SubscriptionStore (Transaction API); PremiumPaywallView; client-side entitlement (server-side mirror deferred) | 129 | af3c7b5 |
| R23 | round_ship_assets_r1 | AppIcon 1024 (PIL-generated coral gradient + heart + wordmark); AccentColor; LaunchLogo; UILaunchScreen; PrivacyInfo.xcprivacy (Apple 2024 manifest) | 129 | 4d1a90f |
| R24 | round_e2e_testflight_r1 | SupabaseE2ETests (2 tests, SKIP unless env set); archive.sh + export-options.plist; harvest_screenshots.sh; e2e_setup.md; launchability-review-2026.md rewritten as final status | 129+2skip | 6d2cfce |

## 3. What "launchable" means now

**Implemented + verified (local build + test):**
- Email/password auth → Supabase Auth
- Profile table with display name + cloud-synced preferences
- Groups (couple/group) with create + invite-code join + rotate + realtime roster
- Memories CRUD backed by Postgres with RLS; offline cache; realtime postgres_changes
- Photo upload to private `memories` Storage bucket with signed URLs
- StoreKit 2 paywall with 2 products (monthly/yearly) via local .storekit config
- AppIcon + LaunchScreen + PrivacyInfo.xcprivacy

**Deferred / operator action required before App Store submission:**
1. Supabase Dashboard → Auth → Policies → enable HIBP leaked-password protection
2. Supabase Dashboard → Auth → Email → disable email confirmation OR configure SMTP
3. Apple Developer enrollment + TEAM_ID for codesigning (`DEVELOPMENT_TEAM` currently "")
4. App Store Connect product creation with IDs matching StoreKitConfiguration.storekit
5. Professional AppIcon + marketing assets (current icon is PIL-generated placeholder)
6. Localized App Store metadata (ko + en) + screenshots
7. Edge Function receipt validation writing to `public.subscriptions` (client-side Transaction API + iCloud sync covers v1, but server mirror adds fraud protection)
8. Sign in with Apple (not required by 4.8 since we only offer email, but polish)

**How to run TestFlight build (once team is acquired):**
```
workspace/ios/scripts/archive.sh <YOUR_TEAM_ID>
```
→ produces `.build/export/MemoryMap.ipa` for App Store Connect upload.

**How to run E2E tests:**
1. Create test user in Supabase Dashboard → Authentication → Users → Add user
2. `UNFADING_E2E_EMAIL=... UNFADING_E2E_PASSWORD=... xcodebuild test ... -only-testing MemoryMapTests/SupabaseE2ETests`

## 4. Full round count

| Block | Rounds | Final test count |
|---|---|---:|
| A (UI) | 12 (R3–R14) | 97 (90 unit + 7 UITest) |
| B (Cloud) | 10 (R15–R24) | 129 (118 unit + 11 UITest) + 2 skipped E2E |

Total commits this date: ~24 rounds + 2 post-round fixes + harness maintenance.
