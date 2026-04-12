# BirdCLEF 2026 Execution Guide

Date: 2026-04-05

This guide defines the Colab-native execution path for BirdCLEF 2026 experiments.

## What Runs Where

- Local machine
  - hosts the harness, manifests, experiment policy, and agent coordination
- Google Drive
  - stores the BirdCLEF 2026 dataset and persistent checkpoints
- Browser Colab session
  - mounts Drive
  - executes training and evaluation jobs on A100

## Drive Layout

Recommended structure:

```text
/content/drive/MyDrive/Kaggle/birdclef-2026/
  birdclef-2026/
    train_audio/
    train.csv
    train_soundscapes/
    train_soundscapes_labels.csv
    taxonomy.csv
    recording_location.txt
    sample_submission.csv
    test_soundscapes/
  birdclef-2026.zip
```

## Required Execution Sequence

1. Open a Colab notebook in the browser and select A100.
2. Mount Google Drive.
3. Confirm the dataset root matches the dataset manifest: `/content/drive/MyDrive/Kaggle/birdclef-2026/birdclef-2026`.
4. Materialize the approved run artifact inside the notebook.
5. Train on group-aware validation folds.
6. Tune thresholds on validation before claiming gains.
7. Write logs and checkpoints back to Drive.

## Submission

Use environment variables for Kaggle credentials and never hardcode them into repo files. The helper script is:

```bash
scripts/submit_birdclef_kaggle.sh submission.csv <NOTEBOOK> <VERSION> "message"
```

## BirdCLEF-Specific Guardrails

- Do not use random clip-level splits if metadata supports source-aware grouping.
- Keep threshold tuning separate from model fitting.
- Treat public-score gains without cross-fold support as suspicious.
- Cache expensive spectrogram features only when the cache key includes preprocessing configuration.
