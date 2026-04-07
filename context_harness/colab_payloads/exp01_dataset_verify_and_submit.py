"""
EXP-01: Dataset Fact Reproduction + Submission Loop Smoke Test
Resolves: BLOCK-01 (Colab/GPU verify), BLOCK-03 (metric confirm), BLOCK-04 (test-only species)

Instructions:
  1. Open Chrome -> Colab -> A100 runtime
  2. Mount Google Drive
  3. Paste this entire script into a single code cell and run

Output: prints JSON artifact to stdout. Copy it to:
  experiment_log/exp01_dataset_verification.json
"""

import json, os, hashlib, sys, datetime
import pandas as pd
import torch

# ─── BLOCK-01: GPU / Runtime Verification ───
gpu_info = {}
if torch.cuda.is_available():
    gpu_info = {
        "gpu_name": torch.cuda.get_device_name(0),
        "vram_gb": round(torch.cuda.get_device_properties(0).total_mem / 1e9, 1),
        "cuda_version": torch.version.cuda,
        "pytorch_version": torch.__version__,
    }
else:
    gpu_info = {"error": "NO GPU DETECTED"}

print("=== BLOCK-01: GPU Verification ===")
print(json.dumps(gpu_info, indent=2))

# ─── Dataset Path ───
BASE = "/content/drive/MyDrive/Kaggle/birdclef-2026/birdclef-2026"
if not os.path.isdir(BASE):
    print(f"FATAL: Dataset path not found: {BASE}")
    sys.exit(1)

# ─── BLOCK-04: Dataset Fact Verification ───
print("\n=== BLOCK-04: Dataset Fact Verification ===")

train_df = pd.read_csv(os.path.join(BASE, "train.csv"))
taxonomy_df = pd.read_csv(os.path.join(BASE, "taxonomy.csv"))
sample_sub = pd.read_csv(os.path.join(BASE, "sample_submission.csv"))
soundscape_labels = pd.read_csv(os.path.join(BASE, "train_soundscapes_labels.csv"))

train_species = set(train_df["primary_label"].unique())
submission_species = [c for c in sample_sub.columns if c != "row_id"]
taxonomy_species = set(taxonomy_df.iloc[:, 0].unique()) if len(taxonomy_df.columns) > 0 else set()

test_only = set(submission_species) - train_species
train_only = train_species - set(submission_species)

# Class breakdown by class (if taxonomy has class info)
class_col = None
for col in taxonomy_df.columns:
    if col.lower() in ("class", "class_name", "taxon_class"):
        class_col = col
        break

test_only_by_class = {}
if class_col:
    for sp in test_only:
        row = taxonomy_df[taxonomy_df.iloc[:, 0] == sp]
        if len(row) > 0:
            cls = row[class_col].values[0]
            test_only_by_class.setdefault(cls, []).append(sp)

# Count train audio files
train_audio_dir = os.path.join(BASE, "train_audio")
audio_file_count = 0
if os.path.isdir(train_audio_dir):
    for root, dirs, files in os.walk(train_audio_dir):
        audio_file_count += len([f for f in files if f.endswith(('.ogg', '.wav', '.mp3', '.flac'))])

dataset_facts = {
    "num_train_recordings": len(train_df),
    "num_train_audio_files": audio_file_count,
    "num_train_species": len(train_species),
    "num_submission_species": len(submission_species),
    "num_taxonomy_species": len(taxonomy_df),
    "num_test_only_species": len(test_only),
    "test_only_species_list": sorted(list(test_only)),
    "test_only_by_class": {k: sorted(v) for k, v in test_only_by_class.items()},
    "num_train_only_species": len(train_only),
    "train_only_species_list": sorted(list(train_only)),
    "num_soundscape_files": soundscape_labels["filename"].nunique() if "filename" in soundscape_labels.columns else "unknown",
    "num_soundscape_segments": len(soundscape_labels),
    "sample_submission_shape": list(sample_sub.shape),
    "sample_submission_columns_count": len(sample_sub.columns),
    "sample_submission_default_value": float(sample_sub[submission_species[0]].iloc[0]) if len(submission_species) > 0 else None,
}

print(json.dumps(dataset_facts, indent=2))

# ─── Blackboard claim comparison ───
print("\n=== Claim Verification ===")
claims = {
    "num_train_recordings": 35549,
    "num_train_species": 206,
    "num_submission_species": 234,
    "num_test_only_species": 28,
}
for key, expected in claims.items():
    actual = dataset_facts[key]
    status = "CONFIRMED" if actual == expected else f"MISMATCH (expected {expected}, got {actual})"
    print(f"  {key}: {status}")

# ─── Generate uniform-prior submission CSV ───
print("\n=== Generating Uniform-Prior Submission ===")
uniform_value = 1.0 / len(submission_species)
submission = sample_sub.copy()
for col in submission_species:
    submission[col] = uniform_value

submission_path = "/content/drive/MyDrive/Kaggle/birdclef-2026/uniform_prior_submission.csv"
submission.to_csv(submission_path, index=False)
print(f"Saved to: {submission_path}")
print(f"Shape: {submission.shape}, uniform value: {uniform_value:.6f}")

# ─── Full artifact ───
artifact = {
    "exp_id": "EXP-01",
    "name": "Dataset Fact Reproduction + Submission Loop Smoke Test",
    "timestamp": datetime.datetime.now().isoformat(),
    "gpu_info": gpu_info,
    "dataset_facts": dataset_facts,
    "claim_verification": {k: dataset_facts[k] == v for k, v in claims.items()},
    "uniform_submission_path": submission_path,
    "status": "COMPLETE_PENDING_KAGGLE_SUBMISSION",
    "next_steps": [
        "Submit uniform_prior_submission.csv to Kaggle",
        "Log the returned LB score and metric name",
        "Update state.json with confirmed dataset facts"
    ]
}

print("\n=== FULL ARTIFACT (copy to experiment_log/exp01_dataset_verification.json) ===")
print(json.dumps(artifact, indent=2))
