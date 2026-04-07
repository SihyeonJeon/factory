# BirdCLEF CLI Runbook

Date: 2026-04-06

## Model Allocation by Task Complexity

| Provider | Heavy | Default | Light |
|----------|-------|---------|-------|
| Claude | claude-opus-4-6 | claude-sonnet-4-6 | claude-haiku-4-5 |
| Gemini | gemini-2.5-pro | gemini-2.5-flash | gemini-2.5-flash |
| Codex | o3 | o4-mini | o4-mini |

**Routing rule**: use heavy only for critic gates, final selection, deep SOTA synthesis. Use light for format checks, log parsing, template generation.

## Current Blocking Issues (from critic gate)

| Block | Issue | Resolved by |
|-------|-------|-------------|
| BLOCK-01 | Colab MCP / GPU not verified | EXP-01 Colab script |
| BLOCK-02 | No training script for EXP-02 | Codex handoff |
| BLOCK-03 | Metric unconfirmed | Gemini search + EXP-01 submission |
| BLOCK-04 | 28 test-only species unverified | EXP-01 Colab script |

## Execution Sequence

### Phase A: Resolve Blockers (parallel)

These 3 commands can run simultaneously in separate terminals:

```bash
# Terminal 1: Gemini confirms metric (BLOCK-03)
scripts/run_gemini_handoff.sh \
  context_harness/handoffs/birdclef2026_gemini_metric_confirm.json \
  gemini-2.5-flash

# Terminal 2: Codex builds training script (BLOCK-02)
scripts/run_codex_handoff.sh \
  context_harness/handoffs/birdclef2026_codex_training_script.json \
  o4-mini

# Terminal 3: User runs EXP-01 in Colab (BLOCK-01, BLOCK-04)
# Paste context_harness/colab_payloads/exp01_dataset_verify_and_submit.py
# Then submit uniform_prior_submission.csv to Kaggle
```

### Phase B: Critic Re-review

```bash
# After EXP-01 results are logged:
scripts/run_claude_handoff.sh \
  context_harness/handoffs/birdclef2026_claude_critic_gate.json \
  opus
```

### Phase C: Execute EXP-02

```bash
# User pastes exp02_effnet_b0_train.py into Colab and runs it
# After training completes, save artifact to experiment_log/
```

### Phase D: Backbone Ablations (EXP-03 || EXP-04)

```bash
# Claude architect reviews EXP-02 results and queues next experiments
scripts/run_claude_handoff.sh \
  context_harness/handoffs/birdclef2026_claude_experiment_queue.json \
  sonnet
```

## Notes

- Run all commands from the repository root.
- Colab execution is manual: paste payload scripts into Colab cells.
- Keep Colab execution separate from CLI reasoning.
- Each agent output should be saved to `experiment_log/` before the next step.
