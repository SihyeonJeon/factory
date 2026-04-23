---
round: round_launchability_r1
stage: operator_amendment
status: decided
participants: [claude_code, codex]
decision_id: 20260423-r14-uitests-gitignore
contract_hash: none
created_at: 2026-04-23T10:05:00Z
codex_session_id: 019db43d-746e-73b3-b33c-5dda3770df91
---
# R14 post-close fix: un-gitignore UITests/ directory

## Context
R14 commit `7530197` added the `UnfadingUITests` target to `workspace/ios/project.yml` and wrote `workspace/ios/UITests/UnfadingUITests.swift` via Codex dispatch. Stop-hook caught that the `.gitignore` allow-list (written in R2 foundation_reset) only un-ignored `App/`, `Features/`, `Shared/`, `Tests/`, and `project.yml`. It did NOT include `UITests/`, so the UITest source file was written to disk but never tracked by git. A fresh clone would lack the file and fail to build the UITest target that `project.yml` references.

Severity: governance defect — R14 close was empirically valid locally (7/7 UITests PASS, xcresult captured), but the repo state is internally inconsistent. The commit references a target whose source is unreachable from git history.

## Decision
1. Amend `.gitignore`: add `!workspace/ios/UITests/` to the allow-list block.
2. Stage and commit `.gitignore` + `workspace/ios/UITests/UnfadingUITests.swift` together as a post-round governance fix commit.
3. This is an operator-layer infra fix (repo-root `.gitignore`), not an in-round Swift change — matches the pattern of commit `44e2a1d` (R2 initial un-gitignore).

## Challenge Section
### Objection
Could also revert R14 (strip UITests target from project.yml). Rejected — the UITests work is evidence-load-bearing for R14 launchability verification (screenshot-based surface audit).

### Risk
`.gitignore` is not inside any round's `file_whitelist.txt`. Accepted: gitignore and related repo-root infra sit above the round-contract layer; changes are governed by meeting trail (this file) rather than whitelist. Precedent: commit `44e2a1d` (R2).

### Rejected alt
Add `.gitignore` to R14 whitelist via `cmd_amend` retroactively. Rejected — R14 is already `closed`; reopening for a repo-root file pollutes the round artifact.

## Expected outcome
- `git check-ignore workspace/ios/UITests/UnfadingUITests.swift` returns nothing (no longer ignored).
- Fresh clone can build `UnfadingUITests` target.
- R14 lock/evidence remains untouched; `check_operator_round.py gates round_launchability_r1` still clean.
