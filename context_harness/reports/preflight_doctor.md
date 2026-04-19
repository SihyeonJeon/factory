# Preflight Doctor

- all_ok: True
- evaluator_mode: playwright_e2e_plus_visual_qa

## Provider readiness
### claude_api
- status: ready
- binary: ready
- auth: ready
- session: ready
- local readiness: ready
- live connectivity: skipped
- runtime: claude-agent-sdk ok
- mcp: claude mcp runtime ok
- lane impact: planning, architecture, review, operator
- notes: Session=Claude CLI login present. Smoke=skipped. Active transport=claude-cli.

### codex_cli
- status: ready
- binary: ready
- auth: ready
- session: ready
- local readiness: ready
- live connectivity: skipped
- runtime: codex-cli 0.118.0
- mcp: Name        Command  Args                                          Env                                                                 Cwd  Status   Auth       
- lane impact: implementation, refactor, parallel worktrees
- notes: Session=expires at 2026-04-20T11:57:57+00:00 (13451 min remaining). Smoke=skipped. Project is trusted in ~/.codex/config.toml.

### xcode_mcp
- status: ready
- binary: ready
- auth: ready
- session: ready
- local readiness: ready
- live connectivity: unknown
- runtime: Xcode 26.4
Build version 17E192
- mcp: project .mcp.json configured
- lane impact: native build, simulator, preview, UI testing
- notes: Global client registration may still be missing even with project fallback config.

## Lane readiness
### operations
- status: ready
- blockers: none

### product
- status: ready
- blockers: none

### planning
- status: ready
- blockers: none

### development
- status: ready
- blockers: none

### evaluation
- status: ready
- blockers: none
