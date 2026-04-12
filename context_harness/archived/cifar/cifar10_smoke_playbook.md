# CIFAR-10 Smoke Playbook

Date: 2026-04-03

Use this playbook to validate the harness end-to-end before any serious method search.

## Inputs

- Handoff: `context_harness/handoffs/cifar10_smoke_handoff.json`
- Dataset manifest: `context_harness/manifests/datasets/cifar10.json`
- Method manifest: `context_harness/manifests/methods/cifar10_resnet18_smoke.json`
- Run manifest: `context_harness/manifests/runs/cifar10_smoke_run_001.json`
- Eval manifest: `context_harness/manifests/evals/cifar10_smoke_eval_001.json`

## Sequence

1. `gemini-cli`
   - Collect current CIFAR-10 baseline references and common reproduction details.
   - Write citations into `experiment_log/architecture_proposal.json`.

2. `claude-code-cli` as `architect`
   - Convert the manifests and citations into a concrete architecture proposal.
   - Fill `experiment_log/architecture_proposal.json`.

3. `claude-code-cli` as `critic`
   - Review the proposal and reject if evidence, feasibility, or reproducibility fields are missing.
   - Write `experiment_log/critique_architecture_proposal.json`.

4. `codex-cli`
   - Implement the baseline training/evaluation/logging code from the approved manifests.
   - Do not change dataset policy or benchmark definitions.

5. `claude-code-cli` as `critic`
   - Review the implementation artifact before GPU spend.

6. `trainer` via Colab MCP
   - Execute `cifar10-smoke-001`.
   - Write `experiment_log/training_run_cifar10-smoke-001.json`.

7. `evaluator` via Colab MCP
   - Evaluate the best checkpoint.
   - Write `experiment_log/eval_report_cifar10-smoke-001.json`.

8. `explainer`
   - Analyze convergence and failure modes.
   - Write `experiment_log/analysis_cifar10_smoke_001.json`.

9. `selector`
   - Decide whether the harness passes smoke validation or needs another repair cycle.
   - Write `experiment_log/selection_final.json`.

## Pass Criteria

- all required artifacts are present
- no stage invents evidence
- rerunning the same config with the same seed produces materially consistent results
- the evaluator can trace the final metric back to a checkpoint and run log

## Promotion Rule

Do not start CIFAR-100 until:

- this playbook completes once successfully
- one rerun confirms reproducibility
- the code path no longer hardcodes CIFAR-10 assumptions outside manifests
