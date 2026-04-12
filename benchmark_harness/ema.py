from __future__ import annotations

import copy

import torch


class ModelEMA:
    def __init__(self, model: torch.nn.Module, decay: float = 0.999) -> None:
        self.module = copy.deepcopy(model).eval()
        self.decay = decay
        for parameter in self.module.parameters():
            parameter.requires_grad_(False)

    @torch.no_grad()
    def update(self, model: torch.nn.Module) -> None:
        model_state = model.state_dict()
        for key, ema_value in self.module.state_dict().items():
            model_value = model_state[key].detach()
            if not torch.is_floating_point(model_value):
                ema_value.copy_(model_value)
                continue
            ema_value.mul_(self.decay).add_(model_value, alpha=1.0 - self.decay)
