# Change Record

## Before this conversation

- The machine had Codex CLI, Claude Code, and Gemini CLI installed, but the harness behavior was still centered on older triad assumptions.
- Claude was configured mainly as a CLI participant, not as the planning and review API backend.
- The router and runner mixed outdated task names, old model assumptions, and incomplete worktree orchestration.
- iOS tooling was incomplete because full `Xcode.app` was not active, and no explicit release-gate policy tied AI output to Apple HIG review.
- Context separation for token efficiency existed only partially and was not enforced across product, planning, engineering, and evaluation lanes.

## Current state

- The harness is now organized as a company-style team with operations, product, planning, engineering, and evaluation roles.
- Claude is assigned to API-driven planning, architecture, arbitration, review, and operator duties.
- The Claude provider now prefers `claude-agent-sdk`, enabling adaptive thinking, structured outputs, project settings loading, and future MCP/subagent expansion.
- Codex CLI is assigned to implementation and parallel execution work.
- Gemini CLI is assigned to market research and screenshot-heavy visual QA.
- The router now supports explicit preferred-role dispatch instead of only task-type routing.
- The orchestrator now writes structured handoffs, runs delivery in isolated worktrees, merges into a dedicated integration worktree, compacts blackboard context, and supports evaluation-to-remediation loops.
- The orchestrator now includes a preflight doctor, handoff ledger, operator journal, and explicit evaluator-mode documentation.
- The orchestrator now loads project `.env` at runtime so provider authentication survives new subprocesses and restarted sessions.
- The evaluator lane now runs a Playwright-style smoke pass before review and HIG arbitration, and stores the result as a reusable artifact.
- Policy files now define HIG release gates, fork criteria, and install steps.
- User-level shell and CLI settings were aligned for the new harness shape.
- Recommended frontline tools were partially installed; `swiftlint` still awaits full Xcode installation.

## Intent

- Reduce hallucination by separating implementation from evaluation.
- Reduce self-approval bias by requiring an external review lane before release confidence.
- Reduce token waste by passing short handoffs through dedicated directories rather than replaying full history.
- Keep iOS output closer to App Store expectations by treating HIG as a blocking gate instead of a soft guideline.
- Move merge-back and autonomous remediation into the operator lane instead of leaving them implicit.
- Make subagent spawning predictable by enforcing bounded scope, disjoint ownership, and explicit verification artifacts.
