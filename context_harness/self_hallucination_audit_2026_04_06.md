# Self-Hallucination Audit — 2026-04-06

## Purpose

Record claims made during harness setup that exceeded the evidence actually available in this session, then restore the harness to a stricter evidence standard.

## Overclaimed Or Insufficiently Grounded Items

1. Metric certainty
- Prior wording implied BirdCLEF 2026 metric was effectively confirmed as ROC-AUC.
- Actual evidence in this session: indirect only.
- What was available:
  - official Kaggle overview page was not readable through the available web tooling
  - submission format reasoning
  - prior-year precedent
- Correct status: working assumption pending logged confirmation.

2. Dataset facts marked as "confirmed via Colab"
- Prior wording claimed dataset counts and test-only class facts were confirmed via Colab.
- Actual evidence in this session: no successful Colab MCP session and no logged Colab artifact were produced.
- Correct status: unverified local claim until reproduced in a logged run or script artifact.

3. Active baseline promotion
- Prior state promoted concrete baseline manifests as if the harness had already selected an active experimental anchor.
- Actual evidence in this session: no architect proposal, no critic gate artifact, no completed Colab training run.
- Correct status: candidate manifests exist, but no active run should be treated as approved.

4. Role-boundary drift
- Local prototype model and metric code was added directly during harness setup.
- That is acceptable as scaffolding, but not as evidence that the harness selected or validated those methods.
- Correct interpretation: prototype support exists in-repo; actual competition direction still requires architect proposal, critic approval, and Colab execution.

## Restorative Actions

- Downgrade unverified competition and dataset claims to working assumptions.
- Remove autonomous workflow language that bypasses the main harness review chain.
- Require architect and critic artifacts before naming an active run.
- Keep prototype code available, but treat it as implementation inventory rather than validated strategy.

## Operational Rule Going Forward

If a fact cannot be tied to:
- an official readable source, or
- a logged local / Colab artifact in `experiment_log/`,

then it must be labeled as one of:
- working assumption
- candidate hypothesis
- insufficient evidence
