# Iterative Pseudo-Labeling Policy — BirdCLEF 2026

## Loop Contract

Each pseudo-label round must follow:

1. select source model or ensemble
2. generate predictions on unlabeled or submission-like audio
3. filter by explicit confidence or consensus rule
4. merge pseudo labels with provenance
5. retrain
6. evaluate against the prior round
7. review for leakage and score inflation

## Required Round Metadata

- `pseudo_label_round`
- source run IDs or ensemble ID
- confidence thresholds or consensus rule
- accepted sample count
- rejected sample count
- merge ratio versus supervised data
- resulting dataset hash

## Stop Conditions

- no meaningful offline gain versus previous round
- public leaderboard regression
- critic flags likely leakage or collapse
- inference budget pressure makes the added model family impractical

## Promotion Rule

Round `n + 1` is allowed only if round `n` has a complete evaluator report and critic sign-off.
