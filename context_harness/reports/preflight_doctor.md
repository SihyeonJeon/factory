# Preflight Doctor

- all_ok: False
- evaluator_mode: playwright_e2e_plus_visual_qa

## Provider readiness
### claude_api
- status: blocked
- binary: blocked
- auth: blocked
- session: blocked
- local readiness: blocked
- live connectivity: skipped
- runtime: claude-agent-sdk unavailable
- mcp: claude mcp runtime ok
- lane impact: planning, architecture, review, operator
- notes: Session=ANTHROPIC_API_KEY missing. Smoke=skipped. Active transport=claude-api.

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
- notes: Session=expires at 2026-04-20T11:57:57+00:00 (9999 min remaining). Smoke=skipped. Project is trusted in ~/.codex/config.toml.

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
- status: blocked
- blockers: claude_api_unavailable

### product
- status: blocked
- blockers: claude_cli_unavailable

### planning
- status: blocked
- blockers: claude_api_unavailable

### development
- status: ready
- blockers: none

### evaluation
- status: blocked
- blockers: playwright_missing, claude_cli_unavailable, native_ios_project_missing
