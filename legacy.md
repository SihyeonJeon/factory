# Legacy Review

This file records code and content that appear legacy, redundant, or no longer on the default execution path.

Deletion is intentionally deferred. The goal here is only to classify and explain.

## Decision labels

- `keep`: active and still part of the current harness
- `legacy-candidate`: likely removable after one more pass
- `archive-only`: keep only as historical reference
- `needs-migration`: still contains useful logic, but does not match the current harness shape

## Active core

- `master_router.py`
  - `keep`
  - Current router for the company-style harness.
- `orchestrator.py`
  - `keep`
  - Current intake, delivery, evaluation, and change-record entrypoint.
- `run_factory.py`
  - `keep`
  - Thin wrapper over the new orchestrator.
- `harness/`
  - `keep`
  - Shared loader and provider runtime for the new architecture.
- `context_harness/team_manifest.json`
  - `keep`
  - Source of truth for role, provider, and routing definitions.
- `context_harness/fork_policy.json`
  - `keep`
  - Machine-readable fork policy used by the orchestrator.
- `context_harness/00_system_rules.md`
  - `keep`
  - Current constitution for the company-style harness.
- `context_harness/policies/ios_hig_guardrails.md`
  - `keep`
  - Current HIG release guidance.
- `context_harness/policies/fork_policy.md`
  - `keep`
  - Human-readable explanation of fork criteria.

## Clear legacy candidates

- `context_harness/roles/architect.prompt`
  - `legacy-candidate`
  - Old single-agent architect prompt. The new system uses `team_manifest.json` and orchestrator-built role prompts instead.
- `context_harness/roles/coder.prompt`
  - `legacy-candidate`
  - Old coder prompt from the triad flow, superseded by current role routing.
- `context_harness/roles/qa.prompt`
  - `legacy-candidate`
  - Old QA prompt, not referenced by the current orchestrator.
- `context_harness/roles/reviewer.prompt`
  - `legacy-candidate`
  - Old reviewer prompt, superseded by current role prompts and router.
- `context_harness/roles/harness_architect.json`
  - `legacy-candidate`
  - Old role-policy JSON from the previous harness generation.
- `context_harness/roles/harness_coder.json`
  - `legacy-candidate`
  - Same issue; still describes the older architect/coder split.
- `context_harness/roles/harness_qa.json`
  - `legacy-candidate`
  - Same issue; old QA lane schema.
- `context_harness/roles/harness_reviewer.json`
  - `legacy-candidate`
  - Same issue; not part of the current router/orchestrator path.
- `agents/architect/CLAUDE.md`
  - `legacy-candidate`
  - Old role file name does not match current canonical role id `ios_architect`.
- `agents/ui-coder/CLAUDE.md`
  - `legacy-candidate`
  - Old naming and assumptions from the earlier split.
- `agents/logic-coder/CLAUDE.md`
  - `legacy-candidate`
  - Same; old role naming.
- `agents/qa/CLAUDE.md`
  - `legacy-candidate`
  - Replaced conceptually by `red_team_reviewer`, `hig_guardian`, and `visual_qa`.

## Probably redundant with newer replacements

- `SETUP_CHECKLIST.md`
  - `legacy-candidate`
  - Overlaps with `context_harness/install_checklist.md`.
  - Keep only if you want a shorter operator-facing checklist at repo root.
- `scripts/setup_frontier_harness.sh`
  - `legacy-candidate`
  - Overlaps with `setup_env.sh`, `scripts/install_frontline_tools.sh`, and `scripts/bootstrap_user_configs.sh`.
  - Also still installs `swiftlint` and `xcodes` eagerly, which is fragile before full Xcode exists.
- `scripts/apply_home_harness.py`
  - `legacy-candidate`
  - Older template-based home config applier. Current flow uses simpler explicit bootstrap scripts.
- `home_templates/claude.settings.patch.json`
  - `legacy-candidate`
  - Only used by `scripts/apply_home_harness.py`.
- `home_templates/gemini.settings.patch.json`
  - `legacy-candidate`
  - Same.
- `home_templates/claude_agents/`
  - `legacy-candidate`
  - Same. Also overlaps with the repo-local `agents/` directory.

## Archive-only content

- `archived_workspaces/failed_app_1775023084/`
  - `archive-only`
  - Historical failed output, not part of the current harness path.
  - Keep only for reference or regression comparison.
- `log.txt`
  - `archive-only`
  - Looks like a run artifact rather than durable source.
- `modules/qa_testing/error_screenshot.png`
  - `archive-only`
  - Static artifact; useful only as evidence.
- `context_harness/reports/change_record.md`
  - `archive-only`
  - Intended historical report, not executable configuration.

## Needs migration, not immediate deletion

- `modules/qa_testing/auto_qa_loop.py`
  - `needs-migration`
  - Still contains useful QA automation, but it is aligned to the older flow using `current_bug_report.md`, `sprint_contract.json`, and direct bug-fix loops.
  - Not currently invoked by the new orchestrator.
- `modules/qa_testing/hig_checker.py`
  - `needs-migration`
  - Still useful and active as a utility, but not yet wired into the new `orchestrator.py` evaluation path.
- `modules/market_research/scraper_and_analyzer.py`
  - `needs-migration`
  - Still generates `01_market_insight.md`, `02_generated_prd.md`, `target_decision.json`, and `sprint_contract.json`.
  - Valuable logic exists, but its outputs follow the older artifact layout rather than the new `handoffs/`, `prd/`, and `reports/` structure.
- `modules/publishing/deploy_and_monitor.py`
  - `needs-migration`
  - References the older context files and has not yet been adapted to the company-style harness.
- `modules/subagents/init_expo_app.sh`
  - `needs-migration`
  - Potentially useful bootstrap helper, but not yet integrated into the current orchestrator path.
- `context_harness/01_market_insight.md`
  - `needs-migration`
  - Still produced by older research logic. Current harness should eventually move this into a product handoff path.
- `context_harness/02_generated_prd.md`
  - `needs-migration`
  - Same; current harness has `context_harness/prd/` for structured PRD storage.
- `context_harness/sprint_contract.json`
  - `needs-migration`
  - Still useful for QA, but it belongs in a newer artifact path once the pipeline is fully migrated.
- `context_harness/current_bug_report.md`
  - `needs-migration`
  - Old QA loop artifact; may be replaced by role-scoped reports.
- `context_harness/target_decision.json`
  - `needs-migration`
  - Older market research artifact, not yet integrated into the new planning path.

## Likely obsolete operational state

- `context_harness/sessions.json`
  - `legacy-candidate`
  - Left over from the earlier session-based flow. The current orchestrator does not use it.
- `context_harness/arbitration_meeting.md`
  - `legacy-candidate`
  - Historical artifact from the earlier harness process.
- `context_harness/04_hardware_scaling_strategy.md`
  - `legacy-candidate`
  - Not referenced in the current runtime path.

## Generated caches and install artifacts

- `__pycache__/`
  - `legacy-candidate`
  - Generated files, not source of truth.
- `workspace/node_modules/`
  - `keep`
  - Not legacy by itself. Large generated dependency tree, but part of the app workspace.
- `modules/**/__pycache__/`
  - `legacy-candidate`
  - Generated files only.
- `scripts/__pycache__/`
  - `legacy-candidate`
  - Generated files only.
- `harness/__pycache__/`
  - `legacy-candidate`
  - Generated files only.

## Recommended cleanup order later

1. Remove `context_harness/roles/` after confirming no external workflow still loads those prompt files.
2. Remove old `agents/architect`, `agents/ui-coder`, `agents/logic-coder`, and `agents/qa` once role-file migration is complete.
3. Consolidate setup into one path and retire `SETUP_CHECKLIST.md`, `scripts/setup_frontier_harness.sh`, `scripts/apply_home_harness.py`, and `home_templates/`.
4. Migrate `modules/market_research`, `modules/qa_testing`, and `modules/publishing` to the new artifact layout before deleting old context files.
5. Delete generated caches and stale artifacts after confirming they are not intentionally committed for debugging.
