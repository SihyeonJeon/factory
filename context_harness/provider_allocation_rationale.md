# Provider Allocation Rationale

Date: 2026-04-03

This note records why the harness defaults were changed from an all-Claude structure to a split orchestration model across `claude-code-cli`, `codex-cli`, `gemini-cli`, and `colab-mcp`.

## Allocation Summary

- `claude-code-cli`
  - Best fit for hypothesis framing, ambiguity reduction, critique, and final decision-making.
  - Use as the orchestration lead when the task is under-specified or expensive to run incorrectly.

- `codex-cli`
  - Best fit for repository-local implementation, refactors, tuning scripts, and bounded parallel coding tasks.
  - Use after architecture or evaluation intent is already specified.

- `gemini-cli`
  - Best fit for current external knowledge: papers, docs, benchmark tables, release notes, and community signals.
  - Use before claims about latest best practices or tool strengths are turned into policy.

- `colab-mcp`
  - Only for execution after a reviewed artifact exists.
  - Never use as a planning surface.

## Practical Rule

1. `gemini-cli` gathers external evidence.
2. `claude-code-cli` turns that evidence into an experiment hypothesis and acceptance criteria.
3. `codex-cli` materializes the code/config/script changes.
4. `critic` reviews the artifact.
5. `colab-mcp` executes.

## Why This Matches Harness Engineering

- Expensive GPU time is protected by separating planning from implementation.
- Latest-practice claims are grounded before they influence architecture or evaluation.
- Implementation throughput is decoupled from strategic reasoning.
- Critique remains independent from the producer of the code or proposal.
