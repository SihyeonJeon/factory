# BirdCLEF CLI Handoff Spec

Date: 2026-04-06

This harness uses local CLIs for the three reasoning providers:

- `claude`
- `gemini`
- `codex`

No direct API provider calls are part of the primary workflow.

## Role Split

- `claude`
  - hypothesis design
  - experiment prioritization
  - critique
  - final selection
- `gemini`
  - latest external evidence
  - benchmark and notebook scan
  - prior-art verification
- `codex`
  - code changes
  - data pipeline implementation
  - training/evaluation/submission tooling

## Standard Packet

```json
{
  "task_id": "birdclef-2026-exp-001",
  "objective": "Implement AST baseline with group-aware CV and submission export",
  "success_criteria": [
    "training path runs on Colab A100",
    "validation metric is logged",
    "submission.csv can be generated"
  ],
  "input_artifacts": [
    "context_harness/manifests/datasets/birdclef2026.json",
    "context_harness/manifests/methods/birdclef2026_ast_strong.json"
  ],
  "output_artifacts": [
    "experiment_log/training_run_birdclef2026-ast-strong-001.json",
    "experiment_log/eval_report_birdclef2026-ast-strong-001.json",
    "experiment_log/submission_birdclef2026-ast-strong-001.csv"
  ],
  "evidence_requirements": [
    "diff summary",
    "reproduction command",
    "metric summary"
  ],
  "stop_conditions": [
    "missing Drive mount",
    "missing Colab session",
    "dataset schema mismatch"
  ]
}
```

## Provider-Specific Guidance

- Send `gemini` tasks only when the output depends on current external evidence.
- Send `codex` tasks only when there is a concrete implementation target.
- Send `claude` tasks when ranking experiments, resolving ambiguity, or validating causal claims.
