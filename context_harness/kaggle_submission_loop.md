# Kaggle Submission Loop — BirdCLEF 2026

Date: 2026-04-05

## Purpose

Local CV is necessary but insufficient. The harness must explicitly track the loop from offline validation to Kaggle submission feedback.

## Required Submission Packet

Each submission candidate must include:

- run ids
- fold scheme
- threshold policy
- aggregation policy across chunks and models
- expected failure mode
- reason this submission differs from the last one

## Submission Stages

1. Offline candidate selection
2. Critic review for leakage and overfitting risk
3. Kaggle-formatted inference artifact generation
4. Submission
5. LB feedback logging
6. Divergence analysis between CV and LB

## Divergence Rules

- If LB improves but CV does not, assume possible validation mismatch or luck.
- If CV improves but LB does not, inspect thresholding, grouping, and calibration first.
- If both improve, keep the recipe on the shortlist but require another rerun before overcommitting.

## Daily Discipline

- Use one submission slot for exploitation.
- Use one submission slot for exploration.
- Never submit two highly correlated candidates on the same day if one slot can test a different hypothesis.
