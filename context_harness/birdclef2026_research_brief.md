# BirdCLEF 2026 Research Brief

Date: 2026-04-05

## Task Reframing

This harness no longer optimizes CIFAR image classification. The primary objective is leaderboard score maximization on BirdCLEF 2026, a bioacoustic soundscape classification task built from Brazilian Pantanal recordings.

The public dataset description indicates:

- training audio consists of short single-label recordings resampled to 32 kHz in OGG format
- hidden-test soundscapes are approximately 600 one-minute recordings
- classes include birds, amphibians, mammals, reptiles, and insects

## Why This Is Better Than CIFAR

- The task is less saturated and more aligned with real leaderboard value.
- Strong audio pretraining and thresholding matter, so method choice has larger leverage.
- Source leakage and group-aware validation make experimental rigor meaningful.

## Best Current Method Families To Exploit

- `BEATs`-style audio SSL backbones
  - strong generic audio representations from self-supervised pretraining
- `AST` / `SSAST` / `PaSST`-style spectrogram transformers
  - strong transfer from pretrained spectrogram models
- `HTS-AT`-style hierarchical transformers
  - strong score-to-compute tradeoff for audio classification

## First Three Harness Hypotheses

1. A pretrained AST-style baseline will give the fastest path to a strong offline score.
2. A BEATs-style backbone will outperform AST once threshold tuning and group-aware validation are done correctly.
3. HTS-AT may be the best Pareto choice if A100 time becomes the bottleneck.

## Validation Rules

- Use source-aware or recorder-aware folds where metadata allows it.
- Tune class thresholds on validation, not globally by intuition.
- Treat public-LB-style gains without leakage defense as untrusted.
