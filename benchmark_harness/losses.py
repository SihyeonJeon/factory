from __future__ import annotations

import torch
from torch import nn


class BinaryFocalLoss(nn.Module):
    def __init__(self, gamma: float = 2.0, alpha: float = 0.25) -> None:
        super().__init__()
        self.gamma = gamma
        self.alpha = alpha

    def forward(self, logits: torch.Tensor, targets: torch.Tensor) -> torch.Tensor:
        bce = torch.nn.functional.binary_cross_entropy_with_logits(logits, targets, reduction="none")
        probs = torch.sigmoid(logits)
        pt = targets * probs + (1.0 - targets) * (1.0 - probs)
        alpha_factor = targets * self.alpha + (1.0 - targets) * (1.0 - self.alpha)
        focal_weight = alpha_factor * (1.0 - pt).pow(self.gamma)
        return (focal_weight * bce).mean()


def build_criterion(method_manifest: dict, dataset_manifest: dict) -> nn.Module:
    training_cfg = method_manifest["training"]
    if dataset_manifest["dataset_family"] == "kaggle_birdclef_soundscape":
        loss_name = str(training_cfg.get("loss", "bce")).lower()
        if loss_name == "bce_focal":
            return BinaryFocalLoss()
        if loss_name == "bce_asymmetric":
            return BinaryFocalLoss(gamma=1.5, alpha=0.4)
        return nn.BCEWithLogitsLoss()
    return nn.CrossEntropyLoss(label_smoothing=training_cfg.get("label_smoothing", 0.0))
