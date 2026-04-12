# Agent Onboarding — Research-First Start

Agents in this harness must not begin from "basic CNN + default SGD" thinking.

## Required Understanding Before Proposing Runs

Every architecture or optimization proposal must answer these questions explicitly:

1. What is the best known accuracy reference for this dataset and does it rely on pretraining, ensembling, or both?
2. What mechanism is expected to help: representation quality, regularization, optimizer geometry, or better data usage?
3. Why should the method improve the `accuracy / time / memory` Pareto front instead of only one scalar metric?
4. What evidence would falsify the hypothesis quickly?

## Minimum Baseline Policy

- Smoke validation may use `cifar10_resnet18_smoke`.
- Any serious method work must start from a strong baseline that already includes modern augmentation and regularization.
- On CIFAR-100, the default baseline is `cifar100_wrn28x10_late_sam`.

## Proposal Template

- Dataset:
- Baseline being compared against:
- Mechanism:
- Why this should work better than the current baseline:
- Expected gain:
- Cost increase:
- Failure signature:

## Current Preferred Hypotheses

- Late-phase sharpness-aware optimization captures most of SAM's generalization benefit with smaller wall-clock cost.
- Strong recipes on CIFAR-100 yield more transferable insight than chasing another decimal place on CIFAR-10.
- Single-model gains should be established before ensemble methods are used.
