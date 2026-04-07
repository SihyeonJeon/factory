# Codex Prompt: BirdCLEF 2026 EXP-02 Training Script

아래 프롬프트를 Codex에 그대로 붙여넣어 실행하세요.

---

You are the implementation agent in a multi-agent BirdCLEF 2026 competition harness. Your job is to produce a single self-contained Python script that trains EfficientNet-B0 + GeM pooling on the BirdCLEF 2026 dataset inside Google Colab with an A100 GPU.

## Task Contract

```json
{
  "task_id": "birdclef-2026-codex-training-script-001",
  "objective": "Write context_harness/colab_payloads/exp02_effnet_b0_train.py — a self-contained Colab training script for EXP-02.",
  "output_file": "context_harness/colab_payloads/exp02_effnet_b0_train.py"
}
```

## Confirmed Facts (verified via Colab MCP on 2026-04-06)

- Dataset path: `/content/drive/MyDrive/Kaggle/birdclef-2026/birdclef-2026/`
- 35,549 training recordings, 206 train species, 234 submission species
- 28 test-only species (25 Insecta, 3 Amphibia) with zero training data
- Submission: float probability per species per 5-second window, 234 columns + row_id
- Metric: **macro-averaged ROC-AUC** (skips classes with no true positives)
- GPU: NVIDIA A100-SXM4-40GB
- PyTorch `get_device_properties(0).total_memory` (NOT `total_mem`)

## Hyperparameters (from method manifest `birdclef2026_effnet_b0_gem`)

| Parameter | Value |
|-----------|-------|
| Backbone | EfficientNet-B0 (ImageNet pretrained) |
| Pooling | GeM (learnable p, init=3.0) |
| Optimizer | AdamW, lr=3e-4, weight_decay=0.01, betas=(0.9, 0.999) |
| Scheduler | Cosine with 2 warmup epochs |
| Loss | BCE Focal (gamma=2.0, alpha=0.25) |
| MixUp | alpha=0.15 |
| EMA | decay=0.999 |
| Epochs | 20 |
| Batch size | 64 (halve on OOM, retry) |
| Fold | 0 of 5 (StratifiedGroupKFold, seed=3407) |
| AMP | enabled (autocast + GradScaler) |
| Audio | 32kHz, 5-second segments |
| Spectrogram | Log-Mel, 128 mels, n_fft=2048, hop=512, fmin=20, fmax=16000 |
| Augmentations | SpecAugment (freq_mask=20, time_mask=40), random gain (0.8-1.2), random crop |
| Dropout | 0.3 |

## Requirements

1. **Self-contained**: Do NOT import from `benchmark_harness` or any local package. All code in one file.
2. **Reproducibility**: Set all seeds (random, numpy, torch, cuda). Log seed, git hash placeholder, exact hyperparams.
3. **Group-aware split**: Use `StratifiedGroupKFold` with `primary_label` as stratify, `filename` directory prefix as group.
4. **Per-epoch logging**: Print and collect: epoch, train_loss, val_macro_auroc, classes_scored, lr, gpu_mem_gb, elapsed_sec.
5. **Macro AUROC**: Skip classes with no positive labels (matches competition metric exactly).
6. **Best checkpoint**: Save to Drive with model_state, optimizer_state, epoch, macro_auroc, seed, fold.
7. **OOM handling**: Wrap training in try/except RuntimeError. On OOM, halve batch_size and restart epoch.
8. **Output artifact**: At the end, print a JSON artifact with all metadata, suitable for `experiment_log/training_run_birdclef2026-effnet-b0-001.json`.
9. **Config block at top**: All paths and hyperparameters as constants at the top. No hardcoded paths inline.
10. **1→3 channel**: If input is 1-channel spectrogram, repeat to 3 channels for ImageNet backbone.

## Output

Write a single file: `context_harness/colab_payloads/exp02_effnet_b0_train.py`

Do not explain. Just write the file.
