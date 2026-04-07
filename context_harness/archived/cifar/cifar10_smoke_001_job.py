from __future__ import annotations

import json
import os
import platform
import random
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import torch
import torch.nn as nn
from torch.utils.data import DataLoader, random_split
from torchvision import datasets, transforms
from torchvision.models.resnet import BasicBlock, ResNet


DATASET_MANIFEST = {
    "dataset_id": "cifar10",
    "input_shape": [3, 32, 32],
    "num_classes": 10,
    "splits": {"train": 45000, "validation": 5000, "test": 10000},
    "normalization": {
        "mean": [0.4914, 0.4822, 0.4465],
        "std": [0.2470, 0.2435, 0.2616],
    },
}

METHOD_MANIFEST = {
    "method_id": "cifar10_resnet18_smoke",
    "model": {"family": "resnet", "name": "resnet18", "depth": 18},
    "optimizer": {"name": "sgd", "lr": 0.1, "momentum": 0.9, "weight_decay": 0.0005},
    "scheduler": {"name": "cosine"},
    "training": {
        "epochs": 30,
        "batch_size": 512,
        "label_smoothing": 0.0,
        "amp": True,
    },
    "augmentations": ["random_crop_32_pad_4", "random_horizontal_flip", "normalize"],
}

RUN_MANIFEST = {
    "run_id": "cifar10-smoke-001",
    "seed": 3407,
    "artifacts": {
        "training_log": "experiment_log/training_run_cifar10-smoke-001.json",
        "eval_log": "experiment_log/eval_report_cifar10-smoke-001.json",
        "checkpoint_dir": "checkpoints/cifar10-smoke-001",
    },
}


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def set_seed(seed: int) -> None:
    random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False


def git_hash() -> str:
    try:
        return subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
    except Exception:
        return "unknown"


class CIFARResNet(ResNet):
    def __init__(self, num_classes: int) -> None:
        super().__init__(block=BasicBlock, layers=[2, 2, 2, 2], num_classes=num_classes)
        self.conv1 = nn.Conv2d(3, 64, kernel_size=3, stride=1, padding=1, bias=False)
        self.maxpool = nn.Identity()


def build_transforms(train: bool):
    normalize = transforms.Normalize(
        mean=DATASET_MANIFEST["normalization"]["mean"],
        std=DATASET_MANIFEST["normalization"]["std"],
    )
    ops = []
    if train:
        ops.append(transforms.RandomCrop(32, padding=4))
        ops.append(transforms.RandomHorizontalFlip())
    ops.extend([transforms.ToTensor(), normalize])
    return transforms.Compose(ops)


def build_loaders(data_root: Path):
    train_dataset = datasets.CIFAR10(root=str(data_root), train=True, download=True, transform=build_transforms(True))
    val_dataset = datasets.CIFAR10(root=str(data_root), train=True, download=True, transform=build_transforms(False))
    test_dataset = datasets.CIFAR10(root=str(data_root), train=False, download=True, transform=build_transforms(False))

    generator = torch.Generator().manual_seed(RUN_MANIFEST["seed"])
    train_size = DATASET_MANIFEST["splits"]["train"]
    val_size = DATASET_MANIFEST["splits"]["validation"]
    train_subset, _ = random_split(train_dataset, [train_size, val_size], generator=generator)
    _, val_subset = random_split(val_dataset, [train_size, val_size], generator=generator)

    batch_size = METHOD_MANIFEST["training"]["batch_size"]
    loader_kwargs = {
        "batch_size": batch_size,
        "num_workers": 2,
        "pin_memory": torch.cuda.is_available(),
    }
    return (
        DataLoader(train_subset, shuffle=True, **loader_kwargs),
        DataLoader(val_subset, shuffle=False, **loader_kwargs),
        DataLoader(test_dataset, shuffle=False, **loader_kwargs),
    )


def run_epoch(model, loader, criterion, optimizer, device, amp_enabled: bool):
    is_train = optimizer is not None
    model.train(is_train)
    total_loss = 0.0
    total_correct = 0
    total_seen = 0
    scaler = torch.cuda.amp.GradScaler(enabled=amp_enabled and device.type == "cuda")

    for inputs, targets in loader:
        inputs = inputs.to(device, non_blocking=True)
        targets = targets.to(device, non_blocking=True)

        if is_train:
            optimizer.zero_grad(set_to_none=True)

        with torch.set_grad_enabled(is_train):
            with torch.autocast(device_type=device.type, enabled=amp_enabled and device.type == "cuda"):
                logits = model(inputs)
                loss = criterion(logits, targets)
            if is_train:
                scaler.scale(loss).backward()
                scaler.step(optimizer)
                scaler.update()

        total_loss += loss.item() * targets.size(0)
        total_correct += (logits.argmax(dim=1) == targets).sum().item()
        total_seen += targets.size(0)

    return total_loss / total_seen, total_correct / total_seen


def estimate_flops(model: nn.Module, device: torch.device) -> int:
    total_flops = 0
    hooks = []

    def conv_hook(module, inputs, output):
        nonlocal total_flops
        x = inputs[0]
        batch = x.shape[0]
        out_h, out_w = output.shape[-2:]
        k_h, k_w = module.kernel_size
        total_flops += int(
            batch * out_h * out_w * module.out_channels * (module.in_channels / module.groups) * k_h * k_w
        )

    def linear_hook(module, inputs, output):
        nonlocal total_flops
        total_flops += int(inputs[0].shape[0] * module.in_features * module.out_features)

    for module in model.modules():
        if isinstance(module, nn.Conv2d):
            hooks.append(module.register_forward_hook(conv_hook))
        elif isinstance(module, nn.Linear):
            hooks.append(module.register_forward_hook(linear_hook))

    with torch.no_grad():
        sample = torch.zeros((1, *DATASET_MANIFEST["input_shape"]), device=device)
        model(sample)

    for hook in hooks:
        hook.remove()
    return total_flops


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    output_root = Path(os.environ.get("FACTORY_OUTPUT_ROOT", "/content/factory_outputs"))
    data_root = output_root / "data"
    experiment_root = output_root / "experiment_log"
    checkpoint_root = output_root / RUN_MANIFEST["artifacts"]["checkpoint_dir"]
    output_root.mkdir(parents=True, exist_ok=True)
    checkpoint_root.mkdir(parents=True, exist_ok=True)

    set_seed(RUN_MANIFEST["seed"])
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    train_loader, val_loader, test_loader = build_loaders(data_root)
    model = CIFARResNet(DATASET_MANIFEST["num_classes"]).to(device)
    criterion = nn.CrossEntropyLoss(label_smoothing=METHOD_MANIFEST["training"]["label_smoothing"])
    optimizer = torch.optim.SGD(
        model.parameters(),
        lr=METHOD_MANIFEST["optimizer"]["lr"],
        momentum=METHOD_MANIFEST["optimizer"]["momentum"],
        weight_decay=METHOD_MANIFEST["optimizer"]["weight_decay"],
    )
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(
        optimizer, T_max=METHOD_MANIFEST["training"]["epochs"]
    )

    training_log_path = output_root / RUN_MANIFEST["artifacts"]["training_log"]
    training_log = {
        "run_id": RUN_MANIFEST["run_id"],
        "created_at": now_iso(),
        "seed": RUN_MANIFEST["seed"],
        "git_hash": git_hash(),
        "command": "python cifar10_smoke_001_job.py",
        "environment": {
            "python": platform.python_version(),
            "pytorch": torch.__version__,
            "device": str(device),
        },
        "epochs": [],
        "best_validation_accuracy": None,
        "checkpoint_path": "",
        "status": "running",
    }

    best_val_acc = float("-inf")
    best_checkpoint = None
    bad_epochs = 0
    previous_val_loss = None

    for epoch in range(1, METHOD_MANIFEST["training"]["epochs"] + 1):
        if device.type == "cuda":
            torch.cuda.reset_peak_memory_stats(device)
        start = time.perf_counter()
        train_loss, train_acc = run_epoch(model, train_loader, criterion, optimizer, device, METHOD_MANIFEST["training"]["amp"])
        val_loss, val_acc = run_epoch(model, val_loader, criterion, None, device, METHOD_MANIFEST["training"]["amp"])
        scheduler.step()
        elapsed = time.perf_counter() - start

        peak_mem = None
        if device.type == "cuda":
            peak_mem = torch.cuda.max_memory_allocated(device) / (1024 * 1024)

        training_log["epochs"].append(
            {
                "epoch": epoch,
                "train_loss": train_loss,
                "train_accuracy": train_acc,
                "val_loss": val_loss,
                "val_accuracy": val_acc,
                "lr": optimizer.param_groups[0]["lr"],
                "wall_clock_seconds": elapsed,
                "peak_gpu_memory_mb": peak_mem,
            }
        )
        write_json(training_log_path, training_log)

        if val_acc > best_val_acc:
            best_val_acc = val_acc
            best_checkpoint = checkpoint_root / "best.pt"
            torch.save(
                {
                    "epoch": epoch,
                    "model_state_dict": model.state_dict(),
                    "optimizer_state_dict": optimizer.state_dict(),
                    "val_accuracy": val_acc,
                },
                best_checkpoint,
            )

        if previous_val_loss is not None and val_loss > previous_val_loss:
            bad_epochs += 1
        else:
            bad_epochs = 0
        previous_val_loss = val_loss
        if bad_epochs >= 3:
            break

    training_log["best_validation_accuracy"] = best_val_acc
    training_log["checkpoint_path"] = str(best_checkpoint) if best_checkpoint else ""
    training_log["status"] = "completed" if best_checkpoint else "failed"
    write_json(training_log_path, training_log)

    if not best_checkpoint:
        raise RuntimeError("Training did not produce a checkpoint")

    checkpoint = torch.load(best_checkpoint, map_location=device)
    model.load_state_dict(checkpoint["model_state_dict"])
    model.eval()

    correct = 0
    total = 0
    latency_samples = []
    class_correct = [0 for _ in range(DATASET_MANIFEST["num_classes"])]
    class_total = [0 for _ in range(DATASET_MANIFEST["num_classes"])]
    confusion_matrix = [
        [0 for _ in range(DATASET_MANIFEST["num_classes"])]
        for _ in range(DATASET_MANIFEST["num_classes"])
    ]

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
            preds = logits.argmax(dim=1)
            correct += (preds == targets).sum().item()
            total += targets.size(0)
            for target, pred in zip(targets.cpu().tolist(), preds.cpu().tolist()):
                class_total[target] += 1
                if pred == target:
                    class_correct[target] += 1
                confusion_matrix[target][pred] += 1

    eval_log = {
        "eval_id": "cifar10-smoke-eval-001",
        "run_id": RUN_MANIFEST["run_id"],
        "checkpoint_path": str(best_checkpoint),
        "metrics": {
            "top1_accuracy": correct / total,
            "per_class_accuracy": {
                str(i): class_correct[i] / class_total[i] if class_total[i] else 0.0
                for i in range(DATASET_MANIFEST["num_classes"])
            },
            "confusion_matrix": confusion_matrix,
            "inference_latency_ms": sum(latency_samples) / len(latency_samples),
            "parameter_count": sum(p.numel() for p in model.parameters()),
            "flops": estimate_flops(model, device),
            "peak_inference_memory_mb": (
                torch.cuda.max_memory_allocated(device) / (1024 * 1024) if device.type == "cuda" else None
            ),
        },
        "external_comparisons": [],
        "command": "python cifar10_smoke_001_job.py",
        "status": "completed",
    }
    write_json(output_root / RUN_MANIFEST["artifacts"]["eval_log"], eval_log)

    print(json.dumps({"training_log": str(training_log_path), "eval_log": RUN_MANIFEST["artifacts"]["eval_log"]}, indent=2))


if __name__ == "__main__":
    main()
