from __future__ import annotations

import argparse
import sys
import time
from pathlib import Path

import torch

from .data import build_dataloaders
from .experiment_logging import build_eval_log, write_experiment_log
from .manifests import load_json, resolve_num_classes, resolve_repo_path
from .metrics import (
    calibration_error,
    multiclass_accuracy,
    multilabel_macro_auroc,
    multilabel_macro_f1,
    multilabel_mean_average_precision,
    multilabel_per_class_auroc,
)
from .models import build_model
from .utils import get_device


def _count_parameters(model: torch.nn.Module) -> int:
    return sum(parameter.numel() for parameter in model.parameters())


def _estimate_flops(model: torch.nn.Module, input_shape: tuple[int, int, int, int], device: torch.device) -> int:
    total_flops = 0
    hooks = []

    def conv_hook(module, inputs, output):
        nonlocal total_flops
        x = inputs[0]
        batch_size = x.shape[0]
        out_h, out_w = output.shape[-2:]
        kernel_h, kernel_w = module.kernel_size
        in_channels = module.in_channels
        out_channels = module.out_channels
        groups = module.groups
        total_flops += int(
            batch_size
            * out_h
            * out_w
            * out_channels
            * (in_channels / groups)
            * kernel_h
            * kernel_w
        )

    def linear_hook(module, inputs, output):
        nonlocal total_flops
        batch_size = inputs[0].shape[0]
        total_flops += int(batch_size * module.in_features * module.out_features)

    for module in model.modules():
        if isinstance(module, torch.nn.Conv2d):
            hooks.append(module.register_forward_hook(conv_hook))
        if isinstance(module, torch.nn.Linear):
            hooks.append(module.register_forward_hook(linear_hook))

    model.eval()
    with torch.no_grad():
        sample = torch.zeros(input_shape, device=device)
        model(sample)

    for hook in hooks:
        hook.remove()
    return total_flops


def _total_wall_clock_seconds(training_log: dict) -> float:
    return float(sum(epoch.get("wall_clock_seconds", 0.0) for epoch in training_log.get("epochs", [])))


def _maybe_load_json(path: Path) -> dict | None:
    if not path.exists():
        return None
    return load_json(str(path))


def evaluate_from_manifests(run_manifest_path: str, eval_manifest_path: str, data_root: str, num_workers: int) -> dict:
    run_manifest = load_json(run_manifest_path)
    eval_manifest = load_json(eval_manifest_path)
    training_log = load_json(run_manifest["artifacts"]["training_log"])
    dataset_manifest = load_json(run_manifest["dataset_manifest"])
    method_manifest = load_json(run_manifest["method_manifest"])
    multilabel = dataset_manifest["dataset_family"] == "kaggle_birdclef_soundscape"
    num_classes = resolve_num_classes(dataset_manifest)

    checkpoint_path = training_log["checkpoint_path"]
    if not checkpoint_path:
        raise ValueError("Training log does not contain a checkpoint path")

    device = get_device()
    model = build_model(
        method_manifest,
        num_classes,
        input_shape=tuple(dataset_manifest["input_shape"]),
    ).to(device)
    checkpoint = torch.load(checkpoint_path, map_location=device)
    model.load_state_dict(checkpoint["model_state_dict"])
    model.eval()

    _, _, test_loader = build_dataloaders(
        dataset_manifest=dataset_manifest,
        method_manifest=method_manifest,
        seed=int(run_manifest["seed"]),
        batch_size=method_manifest["training"]["batch_size"],
        num_workers=num_workers,
        data_root=data_root,
    )

    logits_buffer: list[torch.Tensor] = []
    targets_buffer: list[torch.Tensor] = []
    latency_samples = []

    if device.type == "cuda":
        torch.cuda.reset_peak_memory_stats(device)

    with torch.no_grad():
        for inputs, targets in test_loader:
            inputs = inputs.to(device, non_blocking=True)
            targets = targets.to(device, non_blocking=True)

            start = time.perf_counter()
            logits = model(inputs)
            if device.type == "cuda":
                torch.cuda.synchronize(device)
            latency_samples.append((time.perf_counter() - start) * 1000.0 / inputs.size(0))

            logits_buffer.append(logits.cpu())
            targets_buffer.append(targets.cpu())

    logits = torch.cat(logits_buffer, dim=0)
    targets = torch.cat(targets_buffer, dim=0)

    eval_log = build_eval_log(
        eval_id=eval_manifest["eval_id"],
        run_id=run_manifest["run_id"],
        checkpoint_path=checkpoint_path,
        command=" ".join(sys.argv),
    )
    prediction_artifact = resolve_repo_path(f"experiment_log/predictions_{run_manifest['run_id']}.pt")
    torch.save(
        {
            "logits": logits,
            "targets": targets,
        },
        prediction_artifact,
    )
    eval_log["artifacts"]["raw_predictions"] = str(prediction_artifact)
    if multilabel:
        macro_auroc = multilabel_macro_auroc(logits, targets)
        eval_log["metrics"] = {
            "birdclef_leaderboard_score": macro_auroc,
            "roc_auc": macro_auroc,
            "macro_auroc": macro_auroc,
            "per_class_auroc": multilabel_per_class_auroc(logits, targets),
            "macro_f1": multilabel_macro_f1(logits, targets),
            "mean_average_precision": multilabel_mean_average_precision(logits, targets),
            "calibration_error": calibration_error(logits, targets),
            "inference_latency_ms": sum(latency_samples) / len(latency_samples),
            "parameter_count": _count_parameters(model),
            "flops": _estimate_flops(
                model,
                input_shape=(1, *dataset_manifest["input_shape"]),
                device=device,
            ),
            "peak_inference_memory_mb": (
                torch.cuda.max_memory_allocated(device) / (1024 * 1024)
                if device.type == "cuda"
                else None
            ),
        }
    else:
        top1 = multiclass_accuracy(logits, targets.long())
        eval_log["metrics"] = {
            "top1_accuracy": top1,
            "inference_latency_ms": sum(latency_samples) / len(latency_samples),
            "parameter_count": _count_parameters(model),
            "flops": _estimate_flops(
                model,
                input_shape=(1, *dataset_manifest["input_shape"]),
                device=device,
            ),
            "peak_inference_memory_mb": (
                torch.cuda.max_memory_allocated(device) / (1024 * 1024)
                if device.type == "cuda"
                else None
            ),
        }
    eval_log["ablation_verdict"]["axis"] = eval_manifest.get("ablation_axis", "")

    baseline_run_id = eval_manifest.get("baseline_run_id")
    if baseline_run_id:
        baseline_training_path = resolve_repo_path(f"experiment_log/training_run_{baseline_run_id}.json")
        baseline_eval_path = resolve_repo_path(f"experiment_log/eval_report_{baseline_run_id}.json")
        baseline_training_log = _maybe_load_json(baseline_training_path)
        baseline_eval_log = _maybe_load_json(baseline_eval_path)

        comparison = {
            "baseline_run_id": baseline_run_id,
            "ablation_axis": eval_manifest.get("ablation_axis", ""),
        }
        primary_metric_name = (
            dataset_manifest.get("benchmark_targets", {}).get("primary_metric", "roc_auc")
            if multilabel
            else "top1_accuracy"
        )
        if baseline_training_log is not None:
            comparison["validation_accuracy_delta"] = (
                training_log.get("best_validation_accuracy", 0.0) - baseline_training_log.get("best_validation_accuracy", 0.0)
            )
            comparison["wall_clock_seconds_delta"] = (
                _total_wall_clock_seconds(training_log) - _total_wall_clock_seconds(baseline_training_log)
            )
        if baseline_eval_log is not None:
            baseline_primary = baseline_eval_log.get("metrics", {}).get(primary_metric_name)
            current_primary = eval_log["metrics"].get(primary_metric_name)
            if baseline_primary is not None and current_primary is not None:
                comparison[f"{primary_metric_name}_delta"] = current_primary - baseline_primary
            baseline_memory = baseline_eval_log.get("metrics", {}).get("peak_inference_memory_mb")
            current_memory = eval_log["metrics"].get("peak_inference_memory_mb")
            if baseline_memory is not None and current_memory is not None:
                comparison["peak_inference_memory_mb_delta"] = current_memory - baseline_memory
            baseline_latency = baseline_eval_log.get("metrics", {}).get("inference_latency_ms")
            current_latency = eval_log["metrics"].get("inference_latency_ms")
            if baseline_latency is not None and current_latency is not None:
                comparison["inference_latency_ms_delta"] = current_latency - baseline_latency

        eval_log["baseline_comparison"] = comparison

    eval_log["status"] = "completed"
    write_experiment_log(
        f"experiment_log/eval_report_{run_manifest['run_id']}.json",
        eval_log,
    )
    return eval_log


def main() -> None:
    parser = argparse.ArgumentParser(description="Evaluate a baseline from manifests")
    parser.add_argument("--run-manifest", required=True)
    parser.add_argument("--eval-manifest", required=True)
    parser.add_argument("--data-root", default="data")
    parser.add_argument("--num-workers", type=int, default=4)
    args = parser.parse_args()
    evaluate_from_manifests(args.run_manifest, args.eval_manifest, args.data_root, args.num_workers)


if __name__ == "__main__":
    main()
