# Ablation-First Policy

Date: 2026-04-05

This harness does not treat a multi-trick gain as a method claim until the gain is decomposed.

## Why

- Audio classification datasets are easy to overfit with recipe complexity.
- Small metric gains are often caused by interaction effects, variance, or hidden cost shifts.
- A useful method is one whose benefit survives decomposition.

## Required Sequence

1. Establish a strong baseline and rerun it to estimate variance.
2. Introduce one new factor or one tightly justified interaction hypothesis.
3. Measure accuracy, wall-clock time, and peak memory.
4. Remove one claimed ingredient at a time.
5. Ask the critic whether the causal story is still defensible.

## Minimum Evidence For "Method Improvement"

- One baseline rerun.
- One positive run.
- One factor-removal ablation.
- One evaluation report.
- One critic sign-off.

## Reporting Format

Each claimed method change must answer:

- Baseline:
- Changed factors:
- Accuracy delta:
- Wall-clock delta:
- Peak memory delta:
- Which ablation most weakened the gain:
- Is the claim still valid after ablation:

## Benchmark Rule

- BirdCLEF 2026 is the primary benchmark.
- Local proxy metrics (macro_auroc, per_class_auroc, calibration_error) are used for ablation studies.
- Leaderboard submission is the final arbiter of any method claim.
