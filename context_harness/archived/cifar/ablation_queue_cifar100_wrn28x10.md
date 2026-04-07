# CIFAR-100 WRN-28-10 Ablation Queue

Date: 2026-04-05

Baseline:

- run: `cifar100-wrn28x10-late-sam-001`
- method: `cifar100_wrn28x10_late_sam`

## Ordered Ablations

1. `late_sam`
   - run: `cifar100-wrn28x10-no-late-sam-001`
   - purpose: test whether late-phase sharpness-aware optimization is worth its extra cost
2. `mixup`
   - run: `cifar100-wrn28x10-no-mixup-001`
   - purpose: test whether target interpolation is carrying a large share of the gain

## Comparison Contract

Every ablation comparison must report:

- validation accuracy delta against baseline
- test accuracy delta against baseline
- wall-clock delta against baseline
- peak memory delta against baseline
- critic verdict on whether the removed factor appears causal
