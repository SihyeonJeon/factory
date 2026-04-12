from __future__ import annotations

import argparse
import platform
import sys
import time

import torch
import torch.nn.functional as F
from torch import nn

from .data import build_dataloaders
from .ema import ModelEMA
from .experiment_logging import finalize_training_log, init_training_log, log_epoch, write_experiment_log
from .losses import build_criterion
from .manifests import load_json, resolve_num_classes, resolve_repo_path
from .metrics import multiclass_accuracy, multilabel_macro_auroc
from .models import build_model
from .optim import build_optimizer
from .utils import get_device, get_git_hash, set_seed


def _soft_target_cross_entropy(logits: torch.Tensor, targets: torch.Tensor) -> torch.Tensor:
    return torch.sum(-targets * F.log_softmax(logits, dim=1), dim=1).mean()


def _mixup(inputs: torch.Tensor, targets: torch.Tensor, alpha: float, num_classes: int):
    if alpha <= 0:
        return inputs, targets, None
    lam = float(torch.distributions.Beta(alpha, alpha).sample().item())
    permutation = torch.randperm(inputs.size(0), device=inputs.device)
    mixed_inputs = lam * inputs + (1.0 - lam) * inputs[permutation]
    if targets.ndim == 1:
        mixed_targets = lam * F.one_hot(targets, num_classes=num_classes).float()
        mixed_targets += (1.0 - lam) * F.one_hot(targets[permutation], num_classes=num_classes).float()
    else:
        mixed_targets = lam * targets + (1.0 - lam) * targets[permutation]
    return mixed_inputs, mixed_targets, None


def _compute_epoch_metric(logits_buffer: list[torch.Tensor], targets_buffer: list[torch.Tensor], multilabel: bool) -> float:
    logits = torch.cat(logits_buffer, dim=0)
    targets = torch.cat(targets_buffer, dim=0)
    if multilabel:
        return multilabel_macro_auroc(logits, targets)
    return multiclass_accuracy(logits, targets.long())


def _run_epoch(
    model: nn.Module,
    loader,
    criterion,
    optimizer,
    device,
    amp_enabled: bool,
    num_classes: int,
    mixup_alpha: float,
    sam_active: bool,
    multilabel: bool,
    ema_model: ModelEMA | None = None,
):
    is_train = optimizer is not None
    model.train(mode=is_train)
    total_loss = 0.0
    total_seen = 0
    logits_buffer: list[torch.Tensor] = []
    targets_buffer: list[torch.Tensor] = []

    scaler = torch.amp.GradScaler(device.type, enabled=amp_enabled and device.type == "cuda")
    autocast_enabled = amp_enabled and device.type == "cuda"

    for inputs, targets in loader:
        inputs = inputs.to(device, non_blocking=True)
        targets = targets.to(device, non_blocking=True)
        metrics_targets = targets

        if is_train:
            optimizer.zero_grad(set_to_none=True)
            inputs, targets_for_loss, _ = _mixup(
                inputs,
                targets,
                alpha=mixup_alpha,
                num_classes=num_classes,
            )
        else:
            targets_for_loss = targets

        def _forward_backward_pass() -> tuple[torch.Tensor, torch.Tensor]:
            with torch.autocast(device_type=device.type, enabled=autocast_enabled):
                logits = model(inputs)
                if not multilabel and targets_for_loss.ndim == 2:
                    loss = _soft_target_cross_entropy(logits, targets_for_loss)
                else:
                    loss = criterion(logits, targets_for_loss)
            if is_train:
                scaler.scale(loss).backward()
            return logits, loss

        with torch.set_grad_enabled(is_train):
            logits, loss = _forward_backward_pass()

            if is_train:
                if sam_active:
                    scaler.unscale_(optimizer)
                    optimizer.first_step(zero_grad=True)
                    _forward_backward_pass()
                    scaler.unscale_(optimizer)
                    optimizer.second_step(zero_grad=True)
                    scaler.update()
                else:
                    scaler.step(optimizer)
                    scaler.update()
                if ema_model is not None:
                    ema_model.update(model)

        total_loss += loss.item() * targets.size(0)
        total_seen += targets.size(0)
        logits_buffer.append(logits.detach().cpu())
        targets_buffer.append(metrics_targets.detach().cpu())

    epoch_metric = _compute_epoch_metric(logits_buffer, targets_buffer, multilabel=multilabel)
    return total_loss / total_seen, epoch_metric


def train_from_manifest(run_manifest_path: str, data_root: str, num_workers: int) -> dict:
    run_manifest = load_json(run_manifest_path)
    dataset_manifest_path = run_manifest["dataset_manifest"]
    method_manifest_path = run_manifest["method_manifest"]
    dataset_manifest = load_json(dataset_manifest_path)
    method_manifest = load_json(method_manifest_path)

    seed = int(run_manifest["seed"])
    set_seed(seed)
    device = get_device()
    multilabel = dataset_manifest["dataset_family"] == "kaggle_birdclef_soundscape"
    num_classes = resolve_num_classes(dataset_manifest)

    model = build_model(
        method_manifest,
        num_classes,
        input_shape=tuple(dataset_manifest["input_shape"]),
    ).to(device)
    training_cfg = method_manifest["training"]
    optimizer_cfg = method_manifest["optimizer"]
    scheduler_cfg = method_manifest["scheduler"]
    optimizer, is_sam_optimizer = build_optimizer(model, optimizer_cfg)
    mixup_alpha = float(training_cfg.get("mixup_alpha", 0.0))
    sharpness_cfg = training_cfg.get("sharpness_aware", {})
    sam_start_epoch = int(sharpness_cfg.get("start_epoch", 1 if is_sam_optimizer else training_cfg["epochs"] + 1))
    ema_model = ModelEMA(model, decay=float(training_cfg.get("ema_decay", 0.999))) if training_cfg.get("ema", False) else None

    train_loader, val_loader, _ = build_dataloaders(
        dataset_manifest=dataset_manifest,
        method_manifest=method_manifest,
        seed=seed,
        batch_size=training_cfg["batch_size"],
        num_workers=num_workers,
        data_root=data_root,
    )

    criterion = build_criterion(method_manifest, dataset_manifest)
    if scheduler_cfg["name"].lower() != "cosine":
        raise ValueError(f"Unsupported scheduler '{scheduler_cfg['name']}' in harness")
    warmup_epochs = int(scheduler_cfg.get("warmup_epochs", 0))
    cosine_scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(
        optimizer,
        T_max=max(1, training_cfg["epochs"] - warmup_epochs),
    )
    if warmup_epochs > 0:
        warmup_scheduler = torch.optim.lr_scheduler.LinearLR(
            optimizer,
            start_factor=1e-3,
            total_iters=warmup_epochs,
        )
        scheduler = torch.optim.lr_scheduler.SequentialLR(
            optimizer,
            schedulers=[warmup_scheduler, cosine_scheduler],
            milestones=[warmup_epochs],
        )
    else:
        scheduler = cosine_scheduler

    artifact_log = run_manifest["artifacts"]["training_log"]
    checkpoint_dir = resolve_repo_path(run_manifest["artifacts"]["checkpoint_dir"])
    checkpoint_dir.mkdir(parents=True, exist_ok=True)

    training_log = init_training_log(
        run_id=run_manifest["run_id"],
        dataset_manifest_path=dataset_manifest_path,
        method_manifest_path=method_manifest_path,
        seed=seed,
    )
    training_log["git_hash"] = get_git_hash()
    training_log["command"] = " ".join(sys.argv)
    training_log["environment"] = {
        "python": platform.python_version(),
        "pytorch": torch.__version__,
        "device": str(device),
    }
    training_log["strategy"] = {
        "optimizer": optimizer_cfg["name"],
        "mixup_alpha": mixup_alpha,
        "sharpness_aware_start_epoch": sam_start_epoch if is_sam_optimizer else None,
        "metric_name": (
            dataset_manifest.get("benchmark_targets", {}).get("primary_metric", "top1_accuracy")
            if multilabel
            else "top1_accuracy"
        ),
        "ema": bool(training_cfg.get("ema", False)),
        "roc_auc_shadow_metric": bool(multilabel),
    }

    best_val_metric = float("-inf")
    best_checkpoint_path = ""
    bad_epochs = 0
    previous_val_loss = None

    for epoch in range(1, training_cfg["epochs"] + 1):
        sam_active = is_sam_optimizer and epoch >= sam_start_epoch
        if device.type == "cuda":
            torch.cuda.reset_peak_memory_stats(device)
        epoch_start = time.perf_counter()
        train_loss, train_metric = _run_epoch(
            model,
            train_loader,
            criterion,
            optimizer,
            device,
            amp_enabled=bool(training_cfg.get("amp", False)),
            num_classes=num_classes,
            mixup_alpha=mixup_alpha,
            sam_active=sam_active,
            multilabel=multilabel,
            ema_model=ema_model,
        )
        eval_model = ema_model.module if ema_model is not None else model
        val_loss, val_metric = _run_epoch(
            eval_model,
            val_loader,
            criterion,
            optimizer=None,
            device=device,
            amp_enabled=bool(training_cfg.get("amp", False)),
            num_classes=num_classes,
            mixup_alpha=0.0,
            sam_active=False,
            multilabel=multilabel,
        )
        scheduler.step()
        epoch_wall = time.perf_counter() - epoch_start
        peak_gpu_memory_mb = None
        if device.type == "cuda":
            peak_gpu_memory_mb = torch.cuda.max_memory_allocated(device) / (1024 * 1024)

        log_epoch(
            training_log=training_log,
            epoch=epoch,
            train_loss=train_loss,
            train_accuracy=train_metric,
            val_loss=val_loss,
            val_accuracy=val_metric,
            lr=optimizer.param_groups[0]["lr"],
            wall_clock_seconds=epoch_wall,
            peak_gpu_memory_mb=peak_gpu_memory_mb,
        )
        training_log["epochs"][-1]["sam_active"] = sam_active
        write_experiment_log(artifact_log, training_log)

        if val_metric > best_val_metric:
            best_val_metric = val_metric
            best_checkpoint_path = str(checkpoint_dir / "best.pt")
            torch.save(
                {
                    "epoch": epoch,
                    "model_state_dict": eval_model.state_dict(),
                    "optimizer_state_dict": optimizer.state_dict(),
                    "val_accuracy": val_metric,
                    "run_manifest": run_manifest_path,
                },
                best_checkpoint_path,
            )

        if previous_val_loss is not None and val_loss > previous_val_loss:
            bad_epochs += 1
        else:
            bad_epochs = 0
        previous_val_loss = val_loss
        if bad_epochs >= 3:
            break

    finalize_training_log(
        training_log=training_log,
        checkpoint_path=best_checkpoint_path,
        best_validation_accuracy=best_val_metric,
        status="completed" if best_checkpoint_path else "failed",
    )
    write_experiment_log(artifact_log, training_log)
    return training_log


def main() -> None:
    parser = argparse.ArgumentParser(description="Train a baseline from a run manifest")
    parser.add_argument("--run-manifest", required=True)
    parser.add_argument("--data-root", default="data")
    parser.add_argument("--num-workers", type=int, default=4)
    args = parser.parse_args()
    train_from_manifest(args.run_manifest, args.data_root, args.num_workers)


if __name__ == "__main__":
    main()
