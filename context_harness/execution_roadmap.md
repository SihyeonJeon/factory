# Execution Roadmap

Date: 2026-04-05

This roadmap defines how to validate the harness on a small BirdCLEF 2026 proxy split first, then run serious leaderboard-oriented method work on the full BirdCLEF 2026 training set.

## Phase 0. Harness Readiness

Goal: prove that the orchestration loop itself works before chasing SOTA.

Required outputs:

- provider routing is fixed in `team_manifest.json`
- handoff contract is used for every cross-CLI task
- experiment artifacts are written under `experiment_log/`
- Colab MCP can execute a minimal PyTorch job and return metrics

Exit criteria:

- one complete dry-run passes through `architect -> critic -> codex -> trainer -> evaluator -> explainer -> critic -> selector`
- every stage either emits evidence or `insufficient_evidence`

## Phase 0.5. Autonomous Data Cleaning

Goal: clean the training dataset before any model training begins.

Execution:

1. `codex_cli` implements the 6-stage cleaning pipeline from `data_cleaning_policy.md`.
2. `colab_mcp` runs the pipeline on A100 (Silero VAD is a PyTorch model, benefits from GPU).
3. Each stage writes a JSON log artifact to `experiment_log/data_cleaning_stage_{N}_{name}.json`.
4. If any stage exceeds 15% removal rate, the pipeline halts and `architect` reviews.
5. `evaluator` compares raw vs cleaned dataset statistics.
6. `critic` confirms no label leakage or over-aggressive filtering.

Exit criteria:

- all 6 stages complete with logged artifacts
- the 4-way ablation grid (raw / silence / silence+VAD / full) is populated
- architect selects the active cleaning variant before Phase 1 training

This phase is autonomous — no human approval needed unless the escalation trigger fires.

## Phase 1. BirdCLEF 2026 Proxy Smoke

Goal: validate correctness and reproducibility with a small, cheap audio baseline.

Recommended baseline:

- model: compact CNN or lightweight transformer on log-mel spectrograms
- training length: short smoke budget first, then one reproducibility rerun
- augmentations: time masking, frequency masking, gain/noise augmentation
- optimizer: AdamW first, no aggressive tricks in the first run

What each provider does:

- `gemini-cli`
  - collect current BirdCLEF and bioacoustic reference baselines and common reproduction settings
- `claude-code-cli`
  - define the first hypothesis, stop conditions, and acceptance thresholds
- `codex-cli`
  - implement the baseline training/evaluation/logging pipeline
- `colab-mcp`
  - execute the run on A100 and return metrics

Exit criteria:

- same config rerun stays within an acceptable variance band
- logs contain seed, command, git hash, per-epoch metrics, and checkpoint path
- evaluator and critic both approve the evidence chain

## Phase 2. BirdCLEF 2026 Full-Data Research
Goal: optimize leaderboard score on the actual task, not just prove the harness runs.

Search axes:

- architecture: BEATs-style audio SSL backbones, AST/SSAST/PaSST-style spectrogram transformers, HTS-AT-style hierarchical transformers
- optimization: AdamW, EMA, selective SAM, discriminative layer-wise LR decay
- regularization: label smoothing, mixup on spectrograms, focal/asymmetric losses, pseudo-label filtering
- augmentation: SpecAugment, background mixing, random gain, time shift, soundscape chunking
- schedule: cosine decay, warmup, long fine-tuning schedules, snapshot ensembling

Rules:

- treat BirdCLEF 2026 as the primary research benchmark
- change one major axis at a time unless testing an explicit interaction hypothesis
- every run must state expected information gain
- every claimed gain must be followed by at least one factor-removal ablation
- exploratory multi-change runs cannot be used as final evidence for a method claim
- failed runs remain part of the evidence base

Exit criteria:

- at least one strong reproducible BirdCLEF 2026 recipe is selected
- final selection includes leaderboard-aligned score, train time, latency, FLOPs, memory, and reproducibility notes

## Phase 3. Cross-Year Validation

Goal: verify that improvements are not only exploiting one hidden split.

Required refactor:

- separate dataset config from method config
- separate model definition from experiment policy
- standardize dataset adapters, metric schemas, and evaluation reports
- make task manifests dataset-specific instead of hardcoding image assumptions

Minimum abstractions:

- `dataset_manifest`
- `method_manifest`
- `run_manifest`
- `eval_manifest`

Exit criteria:

- changing from BirdCLEF 2026 to previous BirdCLEF years or held-out folds does not require rewriting agent policy
- only manifests, feature extraction, class maps, and benchmark references change

## Phase 4. Leaderboard Hardening

Goal: harden the selected method for leaderboard submission.

Candidate stress tests:

- prior BirdCLEF years
- region- or source-group held-out folds
- noisy or overlapping soundscape validation subsets
- calibration and threshold sweeps

Success criteria:

- the same orchestration loop runs end-to-end on at least one cross-year or cross-group benchmark
- the system identifies whether the gain is representation-driven, threshold-driven, or leakage-prone

## Phase 5. Bioacoustic Benchmark Expansion

After BirdCLEF 2026 and one cross-year validation benchmark, promote to nearby bioacoustic tasks:

- prior BirdCLEF editions
- ecoacoustic call detection tasks
- xeno-canto or iNaturalist-derived transfer sets when allowed
- domain-specific small-data benchmarks if the target methodology needs them

Selection rule:

- prefer tasks that stress different failure modes: source shift, overlap, rare classes, robustness, efficiency

## Operational Loop

For every benchmark:

1. `gemini-cli` gathers latest external evidence and benchmark expectations.
2. `architect` writes the hypothesis and the ranked run queue.
3. `codex-cli` implements only the approved changes.
4. `critic` verifies the artifact before GPU spend.
5. `trainer` runs on Colab MCP.
6. `evaluator` computes benchmark metrics.
7. `explainer` extracts the next hypothesis.
8. `critic` checks whether the claimed gain survives ablation logic.
9. `selector` chooses the current best method.

## Immediate Next Actions

1. Keep a small BirdCLEF proxy fold only for harness validation.
2. Establish a strong pretrained audio baseline and rerun it for variance estimation.
3. Freeze the experiment log schema for BirdCLEF-style ablation reporting.
4. Add one-factor ablation runs before broader multi-trick leaderboard recipes.
