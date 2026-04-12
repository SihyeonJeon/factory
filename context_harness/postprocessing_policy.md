# Post-Processing Policy — BirdCLEF 2026

## Goal

Treat calibration and score transformation as first-class leaderboard levers after model training.

## Supported Axes

- temperature scaling
- power scaling
- classwise bias correction
- fold-merge weighting
- ensemble weighting
- submission-time clipping or floor rules

## Required Procedure

1. Start from frozen model predictions.
2. Tune post-processing on validation or proxy-leaderboard folds only.
3. Log every parameter set and its score delta.
4. Compare the tuned variant against the untuned baseline.

## Guardrails

- No post-processing may be justified by leaderboard gain alone without an offline trace.
- Threshold-sensitive post-processing must declare whether the official metric is confirmed.
- When the official metric remains unverified, prefer monotonic score transforms that are robust across ranking metrics.

## Promotion Rule

Post-processing can be promoted only if it improves score without violating the active inference budget or reproducibility rules.
