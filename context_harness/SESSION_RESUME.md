# Factory Session Resume — 2026-04-23

**Single source of truth for resuming development.** Rewritten during
`round_foundation_reset_r1` to reflect the workspace's actual state. Prior
Sprint 51 / 140-test narrative moved to
[`docs/exec-plans/sprint-history-pre-v5.md`](../docs/exec-plans/sprint-history-pre-v5.md)
as an explicitly-labeled unverified archive.

---

## 0. Harness v5 (current: v5.6)

**Read first this session:**

1. Your loader: `.claude/CLAUDE.md` (Claude Code Operator) or `AGENTS.md` (Codex Operator)
2. Shared persona: `context_harness/operator/OPERATOR.md`
3. Index: `context_harness/operator/FILE_INDEX.md`
4. Precedence + locks + Gate 5: `context_harness/operator/REGULATION.md`
5. Stage matrix + ownership: `context_harness/operator/STAGE_CONTRACT.md`
6. Active round (if any): `context_harness/operator/locks/<round_id>.lock` + `.events.jsonl`

v5 characteristics: equal Claude Code + Codex co-operators, round contracts with
tamper-evident lock events, `amend` evented flow (v5.5), post-close evidence
revalidation (v5.5), CHANGELOG meeting-trail enforcement (v5.6), honest-agent
trust model (tamper-evident, not malicious-fabrication resistant).

Harness version history: see `operator/CHANGELOG.md`.

---

## 1. Reality Baseline (verified 2026-04-23)

| Item | Verified value |
|---|---|
| Date | 2026-04-23 |
| Branch | `master` |
| App name | **Unfading** (Swift target `MemoryMap`) |
| Swift files under `workspace/ios/` | 16 (12 pre-round + 4 reusable modules added in round_foundation_reset_r1) |
| Tests | 28 (10 baseline + 18 new) — see `Tests/MemoryMapTests.swift`, `Tests/UnfadingThemeTests.swift`, `Tests/UnfadingLocalizedTests.swift`, `Tests/UnfadingComponentTests.swift` |
| Tabs | 3 (Map / Rewind / Groups) — Korean labels after round 2 (지도 / 리와인드 / 그룹) |
| Theme | `workspace/ios/Shared/UnfadingTheme.swift` created in round 2; canonical source of colors, radii, spacing, typography, sheet snaps |
| Localization | `workspace/ios/Shared/UnfadingLocalized.swift` created in round 2; plain Swift namespace, Korean strings |
| Reusable components | `UnfadingPrimaryButtonStyle`, `unfadingCardBackground()` modifier |
| Supabase | Not integrated in Swift yet (SDK not added) |
| `workspace/ios/` git tracking | Selective: `App/`, `Features/`, `Shared/`, `Tests/`, `project.yml` tracked; `*.xcodeproj/`, `.build/`, `.deriveddata/` ignored |
| Architecture version | v5.6 (harness) + Round 2 Swift foundation |
| Operator checker | `harness/check_operator_round.py` — `lint`/`audit-operator-layer`/`lock`/`amend`/`gates`/`close` |

## 2. Round Status

### round_deepsight_r1 — CLOSED (2026-04-22)
- Contract-only round. Deliverables: `docs/design-docs/deepsight_tokens.md`, `deepsight_gap_analysis.md`, `deepsight_slicing_manifest.md`.
- Verdict PASS with 3 advisories (see `context_harness/reports/round_deepsight_r1/verdict.md`). Advisory #2 (UnfadingTheme.swift missing) was the tip of a larger gap resolved in round 2.

### round_foundation_reset_r1 — IN PROGRESS (2026-04-23)
- Scope: foundation + refactor + Korean localization; NO new screens.
- Base commit: `44e2a1d`.
- Lock status: active (check `operator/locks/round_foundation_reset_r1.lock`).
- Meeting: `operator/meetings/2026-04-23_round2_foundation_reset_plan.md` (status: decided).
- Deliverables landed: 4 reusable modules, 5 refactored views, 3 new test files (18 new tests).
- Build status: `xcodebuild test` ✅ SUCCEEDED — 28/28 tests pass on iPhone 17 simulator.

## 3. Next Rounds (per `deepsight_slicing_manifest.md`)

1. **round_navigation** — if deepsight's 5-tab structure (map/calendar/compose/rewind/settings) is accepted, implement root routing. Decision pending.
2. **round_map_shell** — map default state, top chrome, sheet defaults, FAB, filter chips, controls. Uses UnfadingTheme tokens from round 2.
3. **round_map_selected_context** — cluster/pin selected states.
4. **round_memory_detail** — member contribution cards, emotion/cost/location sections.
5. **round_memory_composer** — photo grid + inferred place/time confirmation.
6. **round_calendar** — month/year picker + day memory dots.
7. **round_rewind** — immersive rewind card.
8. **round_group_hub** — mode toggle + member management.
9. **round_a11y_sweep** — VoiceOver labels, Dynamic Type, 44pt audit across redesigned surfaces.

## 4. Key Reference Docs

| File | Purpose |
|---|---|
| `context_harness/operator/REGULATION.md` | v5.6 precedence, lock schema, amendment flow, tamper-evident rules |
| `context_harness/operator/STAGE_CONTRACT.md` | 13-stage matrix, ownership zones |
| `context_harness/operator/MEETING_PROTOCOL.md` | Meeting file format + Challenge Section rule |
| `context_harness/operator/FILE_INDEX.md` | Use-case → file pointer (this session reads this first) |
| `context_harness/operator/CHANGELOG.md` | v5.0 → v5.6 amendment history (each entry has meeting pointer) |
| `docs/design-docs/deepsight_tokens.md` | Canonical design token values from deepsight prototype |
| `docs/design-docs/deepsight_gap_analysis.md` | Current-vs-deepsight gap by category |
| `docs/design-docs/deepsight_slicing_manifest.md` | Future-round sequence |
| `docs/exec-plans/sprint-history-pre-v5.md` | Unverified pre-v5 narrative archive (do NOT cite as current truth) |
| `docs/references/coding-conventions.md` | Coding conventions (forward-looking after round 2) |
| `SKILLS.md` | Proven patterns; S-17 checklist is forward-looking post-round-2 |
| `SECURITY.md` | Security rules |

## 5. How to resume

If starting fresh mid-round 2:
1. `python3 harness/check_operator_round.py gates round_foundation_reset_r1` — should show active lock with all base contract files immutable and gate evidence pending.
2. Check `context_harness/reports/round_foundation_reset_r1/evidence/` for current evidence capture state.
3. Verdict + close flow TBD once all deliverables committed.

If starting after round 2 closes:
1. Open a planning meeting for the next slice (e.g., `round_navigation` or `round_map_shell`).
2. Use `cmd_amend` if the round requires expanding whitelist mid-round (available since v5.5).
