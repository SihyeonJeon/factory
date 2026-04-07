# Blackboard — Agent Shared Context

## Domain: BirdCLEF 2026 Leaderboard Optimization on A100

### Competition Metric — Working Assumption (2026-04-06)
- **Submission format**: probability per species per 5-second window
  - Columns: `row_id` + 234 species columns (float probabilities)
  - row_id pattern: `BC2026_Test_{recorder}_{site}_{date}_{time}_{seconds_offset}`
  - Default fill: 1/234 = 0.004274 (uniform prior)
- **Working assumption metric**: **macro-averaged ROC-AUC** (skips classes with no true positive labels in evaluation set)
  - Source: Gemini grounding search (indirect), 2026-04-06
  - Evidence quality: **indirect only** — official Kaggle overview page was not directly readable; inferred from submission format + prior-year precedent
  - Implication: threshold-free ranking metric. Per-class threshold tuning (EXP-10) is a no-op for this metric.
  - "Skip no-positive classes" means test-only species with zero predictions won't penalize — but covering them still helps if they appear in test.
  - **Action required**: confirm via direct official source read before threshold-sensitive experiments
- **Local proxy metrics**: `macro_auroc`, `per_class_auroc`, `calibration_error`

### Dataset Facts — Working Assumption (2026-04-06, pending Colab artifact verification)
| Fact | Value |
|------|-------|
| Training recordings (train_audio) | 35,549 (from train.csv) |
| Train species in train_audio | 206 (from train.csv primary_label) |
| Submission species (taxonomy) | **234** (from sample_submission.csv) |
| Species absent from train_audio | **28** (25 Insecta, 3 Amphibia) — see note below |
| Train soundscapes (labeled segments) | 1,478 labeled 5s segments (from train_soundscapes_labels.csv) |
| Train soundscape labels | multi-label (`;`-separated), expert-annotated |
| Train soundscapes (unlabeled) | additional soundscapes exist without expert labels |
| Class breakdown (train_audio only) | Aves: 162 spp / Amphibia: 32 / Mammalia: 8 / Insecta: 3 / Reptilia: 1 |
| Label column | `primary_label` (iNat taxon ID or eBird code) |
| Collections | iNat + Xeno-Canto (mixed) |
| Location | Pantanal, Mato Grosso do Sul, Brazil |
| Quality metadata | `rating` field (1-5, XC only; 0=unrated; iNat=no rating) |
| Geo metadata | `latitude`, `longitude` per recording |

### Important: "Test-only species" claim needs verification
The 28 species absent from `train.csv` are NOT necessarily zero-shot:
- **Official description states**: "Some species with occurrences in the hidden test data might only have train samples in the **labeled portion of train_soundscapes** and not in the train_audio."
- This means some of the 28 species may have labeled examples in `train_soundscapes_labels.csv`.
- **Action required**: count species coverage in `train_soundscapes_labels.csv` before concluding any species is truly zero-shot.
- Until verified, do NOT plan external data or zero-shot strategies based solely on the train_audio gap.

### Data Sources and Domain Gap
| Source | Domain match to test | Format | Label type |
|--------|---------------------|--------|------------|
| `train_audio/` (via `train.csv`) | **Low** — single-species XC/iNat recordings | short clips | single primary + optional secondary |
| `train_soundscapes/` (via `train_soundscapes_labels.csv`) | **High** — same locations as test | 1-min soundscapes, 5s segments | multi-label, expert-annotated |
| `train_soundscapes/` (unlabeled) | **High** — same locations as test | 1-min soundscapes | unlabeled (pseudo-label candidate) |

### Critical Strategic Implications
1. **train_soundscapes is the highest-value training data** — same domain as test, expert-labeled, multi-label. Must be incorporated into training, not ignored.
2. **28 species absent from train_audio** — some may exist in train_soundscapes_labels.csv; verify before declaring zero-shot.
3. **Multi-label soundscapes**: multiple species per 5s window → multi-label loss (BCE/Focal), not softmax.
4. **Extreme class imbalance** in train_audio: Aves dominates (97.9%), Reptilia has 1 sample.
5. **5-second prediction windows**: model must handle short audio segments.
6. **Unlabeled train_soundscapes** are first-class pseudo-labeling targets (same domain as test).
7. **`rating` field** can be used for sample weighting — high-quality recordings should carry more weight.
8. **Geographic metadata** can inform group-aware splits and regional diversity sampling.

### Target Metrics
- Primary: maximize ROC-AUC on Kaggle hidden test
- Secondary: wall-clock training time, inference budget compliance
- Full reproducibility for every result

### Competition Pressure
- Deadline target: 2026-06-03 (58 days remaining)
- Entry deadline: 2026-05-27
- Submission loop must compare local CV against Kaggle LB
- External data and pseudo-labeling are first-class research axes
- Final promotion decisions must consider Kaggle notebook inference budget

### SOTA Reference Points
| Method | Score | Year | Notes |
|--------|-------|------|-------|
| BirdCLEF 2025 1st (Noisy Student) | 0.933 AUC | 2025 | EfficientNet ensemble + 4-round PL |
| BirdCLEF 2025 2nd (Semi-supervised) | 0.928 AUC | 2025 | ECA-NFNet-L0 + EfficientNetV2-S |
| BirdCLEF 2025 top 2% baseline | 0.902 AUC | 2025 | EfficientNet-B0 + GeM + Quantile-Mix |
| BEATs-style SSL audio backbone | *TBD by architect* | 2023 | Strong generic audio representation prior |
| AST / SSAST / PaSST family | *TBD by architect* | 2021-2022 | Spectrogram transformer family |
| HTS-AT family | *TBD by architect* | 2022 | Efficient hierarchical audio transformer |

### Structural Priorities
- **Train soundscapes integration is prerequisite** — incorporate train_soundscapes_labels.csv before any serious baseline.
- Iterative pseudo-labeling is a first-class loop, not a one-off utility. Unlabeled train_soundscapes are the primary PL target.
- Final selection is ensemble-aware by default.
- Counterintuitive results must feed a revised hypothesis, not only a failure note.
- Verify the 28-species gap against train_soundscapes_labels.csv before committing to external-data or zero-shot strategies.

---

*Experiment entries will be appended below as agents produce results.*
