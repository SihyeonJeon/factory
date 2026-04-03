# MCP Stack

## Active target stack

- `xcodebuild`
  - Purpose: Xcode, simulator, UI testing, build logs, and diagnostics
  - Install target: Claude Code, Codex, and project-scoped `.mcp.json`
  - Context policy: restrict workflows to discovery, simulator control, UI testing, builds, logging, and doctor

## Why this stack

- Matches the 2026 Apple direction for external agentic tools via MCP.
- Reduces custom glue code between the harness and Xcode.
- Lets evaluation and operator lanes pull native artifacts instead of guessing from app code.

## Current blockers

- `AXe` install is blocked by outdated Command Line Tools.
- Claude SDK runtime still needs the current process environment to receive `ANTHROPIC_API_KEY`.

## Next MCP targets

- Add an operator-facing MCP gateway only if multiple MCP servers become hard to coordinate.
- Add design or browser MCP servers only when they feed a concrete evaluation artifact into the harness.
