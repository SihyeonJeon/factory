# Baseline Shortlist — 2026-04-05

This shortlist defines where agents should start before proposing new methods.

## Rule

Do not start from a plain CNN baseline unless the task is purely harness smoke validation.

## Accuracy Ceiling References

- CIFAR-10
  - `Efficient Adaptive Ensembling`
  - Reported test accuracy: `99.612%`
  - First public paper date: `2022-06-15`
  - Why it matters: shows that CIFAR-10 is saturated and that small reported gains can come from ensemble design rather than better single-model representations.
- CIFAR-100
  - `Efficient Adaptive Ensembling`
  - Reported test accuracy: `96.808%`
  - First public paper date: `2022-06-15`
  - Why it matters: harder than CIFAR-10 and still responsive to optimization and representation changes.

## Mechanisms Agents Must Understand

- Large-scale pretraining wins on small datasets because the representation problem is mostly solved before fine-tuning.
- Augmentation and regularization recipes matter as much as architecture on small and medium vision datasets.
- Sharpness-aware optimization often derives most of its benefit late in training, so late-phase SAM is a legitimate efficiency hypothesis rather than a shortcut.
- Ensembles improve the leaderboard, but they can hide whether a single model actually improved.

## Operational Baselines For This Harness

- `cifar10_resnet18_smoke`
  - Purpose: harness validation only
- `cifar100_wrn28x10_late_sam`
  - Purpose: first serious modern baseline
  - Components: WideResNet-28-10, RandAugment, Mixup, Random Erasing, label smoothing, late-phase SAM

## Next Research Directions

- Compare `late_sam` against `always_on_sam` at matched epochs and batch size.
- Compare `WRN-28-10` against a stronger transfer baseline once pretrained backbones are added.
- Move after CIFAR-100 to a harder benchmark such as Tiny-ImageNet or ImageNet-100, not directly to more CIFAR-10 tuning.

## References

- Efficient Adaptive Ensembling for Image Classification, arXiv:2206.07394, first submitted 2022-06-15
- Sharpness-Aware Minimization for Efficiently Improving Generalization, ICLR 2021 / arXiv:2010.01412
- An Image is Worth 16x16 Words: Transformers for Image Recognition at Scale, ICLR 2021 / arXiv:2010.11929
- How to train your ViT? Data, Augmentation, and Regularization in Vision Transformers, 2021 / arXiv:2106.10270
- Solving ImageNet: a Unified Scheme for Training any Backbone to Top Results, arXiv:2204.03475
