from __future__ import annotations

import torch


def _binary_average_precision(probs: torch.Tensor, targets: torch.Tensor) -> float:
    positives = int(targets.sum().item())
    if positives == 0:
        return 0.0
    order = torch.argsort(probs, descending=True)
    sorted_targets = targets[order]
    cumulative_hits = torch.cumsum(sorted_targets, dim=0)
    ranks = torch.arange(1, sorted_targets.numel() + 1, device=sorted_targets.device, dtype=torch.float32)
    precision_at_hits = cumulative_hits[sorted_targets.bool()] / ranks[sorted_targets.bool()]
    return float(precision_at_hits.mean().item()) if precision_at_hits.numel() else 0.0


def _binary_auroc(probs: torch.Tensor, targets: torch.Tensor) -> float:
    probs = probs.float()
    targets = targets.float()
    positives = int(targets.sum().item())
    negatives = int(targets.numel() - positives)
    if positives == 0 or negatives == 0:
        return 0.5

    order = torch.argsort(probs, descending=False)
    sorted_probs = probs[order]
    sorted_targets = targets[order]
    ranks = torch.arange(1, sorted_probs.numel() + 1, device=sorted_probs.device, dtype=torch.float32)

    unique_vals, inverse_indices, counts = torch.unique_consecutive(
        sorted_probs,
        return_inverse=True,
        return_counts=True,
    )
    del unique_vals
    cumulative_counts = torch.cumsum(counts, dim=0)
    start_positions = cumulative_counts - counts + 1
    avg_ranks = (start_positions.float() + cumulative_counts.float()) * 0.5
    tied_ranks = avg_ranks[inverse_indices]

    positive_rank_sum = tied_ranks[sorted_targets > 0.5].sum()
    auc = (positive_rank_sum - positives * (positives + 1) / 2.0) / (positives * negatives)
    return float(auc.item())


def multiclass_accuracy(logits: torch.Tensor, targets: torch.Tensor) -> float:
    preds = logits.argmax(dim=1)
    return float((preds == targets).float().mean().item())


def multilabel_mean_average_precision(logits: torch.Tensor, targets: torch.Tensor) -> float:
    probs = torch.sigmoid(logits)
    scores = []
    for class_idx in range(targets.size(1)):
        scores.append(_binary_average_precision(probs[:, class_idx], targets[:, class_idx]))
    return float(sum(scores) / max(1, len(scores)))


def multilabel_macro_auroc(logits: torch.Tensor, targets: torch.Tensor) -> float:
    """Macro-averaged ROC-AUC that skips classes with no positive labels,
    matching the Kaggle BirdCLEF evaluation protocol."""
    probs = torch.sigmoid(logits)
    scores = []
    for class_idx in range(targets.size(1)):
        col = targets[:, class_idx]
        positives = int(col.sum().item())
        negatives = int(col.numel() - positives)
        if positives == 0 or negatives == 0:
            continue  # skip — matches Kaggle "skip no-positive classes"
        scores.append(_binary_auroc(probs[:, class_idx], col))
    return float(sum(scores) / max(1, len(scores)))


def multilabel_per_class_auroc(logits: torch.Tensor, targets: torch.Tensor) -> list[float]:
    probs = torch.sigmoid(logits)
    return [_binary_auroc(probs[:, class_idx], targets[:, class_idx]) for class_idx in range(targets.size(1))]


def multilabel_macro_f1(logits: torch.Tensor, targets: torch.Tensor, threshold: float = 0.5) -> float:
    preds = (torch.sigmoid(logits) >= threshold).float()
    tp = (preds * targets).sum(dim=0)
    fp = (preds * (1.0 - targets)).sum(dim=0)
    fn = ((1.0 - preds) * targets).sum(dim=0)
    f1 = (2.0 * tp) / (2.0 * tp + fp + fn + 1e-8)
    return float(f1.mean().item())


def calibration_error(logits: torch.Tensor, targets: torch.Tensor) -> float:
    probs = torch.sigmoid(logits)
    return float(torch.mean((probs - targets).pow(2)).item())
