# Data Cleaning Policy — BirdCLEF 2026

## Goal

Improve leaderboard score by reducing non-bird signal contamination before model training and pseudo-labeling.

## Autonomous Execution Model

Data cleaning is an agent-driven pipeline that runs **before training** without requiring human approval for each step. The full sequence is:

1. `codex_cli` implements cleaning scripts from this policy.
2. `colab_mcp` executes them on the training dataset.
3. `evaluator` compares cleaned vs raw dataset statistics.
4. `critic` reviews for label loss, leakage, or over-aggressive filtering.

The pipeline runs autonomously as long as:
- removal rate per stage stays below the `max_removal_rate` guard (default 15%)
- no cleaning rule touches labels
- every stage writes its log artifact

If any guard is violated, the pipeline halts and escalates to `architect` for a judgment call.

## Cleaning Stages (ordered)

### Stage 1: Corrupt / Undecodable File Removal
- Attempt decode with torchaudio; remove files that raise exceptions.
- Log: file count removed, file paths.

### Stage 2: Duplicate Detection
- Compute audio fingerprint (chromaprint or raw waveform hash on first 10s).
- Remove exact duplicates, keeping the entry with the richest metadata.
- Log: duplicate cluster count, files removed.

### Stage 3: Silence Trimming
- Compute RMS energy in 0.5s windows.
- Trim leading/trailing windows below `silence_threshold_db` (default: -50 dB).
- If remaining duration < 1s, flag for review but do not auto-remove.
- Log: clips trimmed count, mean duration removed, flagged-for-review count.

### Stage 4: Human Speech Suppression (Silero VAD)
- Run Silero VAD (torch, runs on A100) per clip.
- Segments with speech probability > 0.7 for > 2s continuous are candidates for removal or masking.
- Strategy options (selected by architect before first run):
  - `remove_clip`: discard the entire clip
  - `mask_segment`: zero out the speech segment and keep the rest
  - `flag_only`: mark but do not alter
- Default strategy: `mask_segment`
- Log: clips affected, segments masked/removed, total duration affected.

### Stage 5: Low-SNR Filtering
- Estimate SNR via spectral flatness or peak-to-RMS ratio.
- Clips below `min_snr_db` (default: 3 dB) are flagged.
- Flagged clips are not auto-removed; they are downweighted during training via sample weight.
- Log: flagged count, SNR distribution summary.

### Stage 6: Clip Length Normalization
- Clips shorter than `min_clip_seconds` (default: 3s) are padded with silence or dropped.
- Clips longer than `max_clip_seconds` (default: 300s) are split into segments.
- Log: padded count, split count, dropped count.

## Required Logging Per Stage

Every stage must write a JSON artifact to `experiment_log/data_cleaning_stage_{N}_{name}.json`:

```json
{
  "stage": 1,
  "name": "corrupt_file_removal",
  "input_file_count": 25000,
  "output_file_count": 24987,
  "removed_count": 13,
  "removal_rate": 0.0005,
  "removed_paths": ["..."],
  "dataset_hash_after": "sha256:...",
  "timestamp": "2026-04-06T..."
}
```

## Guard Rails

- **Max removal rate**: no single stage may remove more than 15% of clips without architect approval.
- **No label mutation**: cleaning never changes species labels. It only removes, trims, or masks audio.
- **No test data access**: cleaning runs on train/train_soundscapes only.
- **Ablation required**: the first training run must compare `raw` vs `cleaned` under the same model config.
- **Pseudo-label ordering**: cleaning must happen before pseudo-label generation, never after. Log the order explicitly.

## Recommended Ablation Grid

After the cleaning pipeline runs, the following 4-way comparison is mandatory before committing to the cleaned dataset:

| Variant | Silence Trim | Speech Mask | Low-SNR Downweight |
|---------|-------------|-------------|-------------------|
| A (raw) | No | No | No |
| B | Yes | No | No |
| C | Yes | Yes | No |
| D (full) | Yes | Yes | Yes |

The variant with the best group-aware CV score under the active baseline model becomes the default dataset for subsequent experiments.

## Evidence Requirement

Cleaning claims are valid only if evaluator reports the score delta and critic signs off on the leakage risk.
