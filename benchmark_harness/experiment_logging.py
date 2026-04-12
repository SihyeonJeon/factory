from __future__ import annotations

from typing import Any

from .manifests import write_json
from .utils import now_iso


def init_training_log(run_id: str, dataset_manifest_path: str, method_manifest_path: str, seed: int) -> dict[str, Any]:
    return {
        "run_id": run_id,
        "created_at": now_iso(),
        "dataset_manifest": dataset_manifest_path,
        "method_manifest": method_manifest_path,
        "seed": seed,
        "git_hash": "",
        "command": "",
        "environment": {
            "python": "",
            "pytorch": "",
            "device": "",
        },
        "epochs": [],
        "best_validation_accuracy": None,
        "checkpoint_path": "",
        "status": "running",
    }


def log_epoch(
    training_log: dict[str, Any],
    epoch: int,
    train_loss: float,
    train_accuracy: float,
    val_loss: float,
    val_accuracy: float,
    lr: float,
    wall_clock_seconds: float,
    peak_gpu_memory_mb: float | None,
) -> None:
    training_log["epochs"].append(
        {
            "epoch": epoch,
            "train_loss": train_loss,
            "train_accuracy": train_accuracy,
            "val_loss": val_loss,
            "val_accuracy": val_accuracy,
            "lr": lr,
            "wall_clock_seconds": wall_clock_seconds,
            "peak_gpu_memory_mb": peak_gpu_memory_mb,
        }
    )


def finalize_training_log(training_log: dict[str, Any], checkpoint_path: str, best_validation_accuracy: float, status: str) -> dict[str, Any]:
    training_log["checkpoint_path"] = checkpoint_path
    training_log["best_validation_accuracy"] = best_validation_accuracy
    training_log["status"] = status
    return training_log


def write_experiment_log(path: str, payload: dict[str, Any]) -> None:
    write_json(path, payload)


def build_eval_log(eval_id: str, run_id: str, checkpoint_path: str, command: str) -> dict[str, Any]:
    return {
        "eval_id": eval_id,
        "run_id": run_id,
        "checkpoint_path": checkpoint_path,
        "artifacts": {},
        "metrics": {},
        "external_comparisons": [],
        "baseline_comparison": {},
        "ablation_verdict": {
            "axis": "",
            "supports_claim": None,
            "summary": "",
        },
        "command": command,
        "status": "running",
    }
