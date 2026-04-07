from __future__ import annotations

import argparse
import csv
from pathlib import Path

from benchmark_harness.manifests import load_json, write_json


def _read_header(path: Path) -> list[str]:
    with path.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.reader(handle)
        return next(reader)


def _count_rows(path: Path) -> int:
    with path.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.reader(handle)
        next(reader)
        return sum(1 for _ in reader)


def main() -> None:
    parser = argparse.ArgumentParser(description="Bootstrap the BirdCLEF 2026 dataset manifest from local metadata")
    parser.add_argument("--dataset-root", required=True, help="Directory containing BirdCLEF metadata files")
    parser.add_argument(
        "--manifest",
        default="context_harness/manifests/datasets/birdclef2026.json",
        help="Dataset manifest path to update",
    )
    args = parser.parse_args()

    dataset_root = Path(args.dataset_root)
    train_metadata = dataset_root / "train.csv"
    sample_submission = dataset_root / "sample_submission.csv"

    if not train_metadata.exists():
        raise FileNotFoundError(f"Missing train metadata: {train_metadata}")
    if not sample_submission.exists():
        raise FileNotFoundError(f"Missing sample submission: {sample_submission}")

    submission_header = _read_header(sample_submission)
    if len(submission_header) < 2:
        raise ValueError("sample_submission.csv does not contain class columns")

    class_labels = submission_header[1:]
    train_rows = _count_rows(train_metadata)

    manifest = load_json(args.manifest)
    manifest["num_submission_species"] = len(class_labels)
    manifest["num_classes"] = len(class_labels)
    manifest["splits"]["train"] = train_rows
    manifest["notes"].append(
        f"Bootstrapped from local metadata: {len(class_labels)} class columns and {train_rows} training rows."
    )
    write_json(args.manifest, manifest)


if __name__ == "__main__":
    main()
