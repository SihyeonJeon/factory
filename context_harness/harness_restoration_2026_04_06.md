# Harness Restoration Note — 2026-04-06

## Restored Principle

This repository is a harness-first system.

That means:
- `architect` proposes
- `critic` approves or blocks
- `codex` implements approved diffs
- `trainer` and `evaluator` execute through Colab MCP
- `explainer` turns surprising outcomes into revised hypotheses
- `selector` chooses the final single model and ensemble

## What Is Not Considered Restored

The harness is not restored merely because:
- model code exists locally
- candidate manifests exist
- a baseline looks plausible on paper

Restoration requires:
- explicit handoff packets
- critic gate artifact
- Colab execution artifact
- evaluator report

## Immediate Next Sequence

1. Run Gemini public-evidence scan.
2. Run Claude architect queue design.
3. Run Claude critic gate.
4. Only then send approved implementation work to Codex.
5. Only then execute via Colab MCP.

## Colab Rule

All serious BirdCLEF development and training claims must come from Colab MCP execution artifacts, not local dry reasoning.
