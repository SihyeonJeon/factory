from __future__ import annotations

from collections.abc import Iterable
from typing import Any

import torch


class SAM(torch.optim.Optimizer):
    def __init__(
        self,
        params: Iterable[torch.nn.Parameter],
        base_optimizer_cls: type[torch.optim.Optimizer],
        rho: float = 0.05,
        adaptive: bool = False,
        **kwargs: Any,
    ) -> None:
        defaults = dict(rho=rho, adaptive=adaptive, **kwargs)
        super().__init__(params, defaults)
        self.base_optimizer = base_optimizer_cls(self.param_groups, **kwargs)
        self.param_groups = self.base_optimizer.param_groups
        self.defaults.update(self.base_optimizer.defaults)

    @torch.no_grad()
    def first_step(self, zero_grad: bool = False) -> None:
        grad_norm = self._grad_norm()
        for group in self.param_groups:
            scale = float((group["rho"] / (grad_norm + 1e-12)).item()) if grad_norm.numel() else 0.0
            adaptive = group.get("adaptive", False)

            for param in group["params"]:
                if param.grad is None:
                    continue
                self.state[param]["old_p"] = param.data.clone()
                e_w = param.grad
                if adaptive:
                    e_w = e_w * param.pow(2)
                param.add_(e_w, alpha=scale)

        if zero_grad:
            self.zero_grad()

    @torch.no_grad()
    def second_step(self, zero_grad: bool = False) -> None:
        for group in self.param_groups:
            for param in group["params"]:
                if param.grad is None:
                    continue
                param.data = self.state[param]["old_p"]
        self.base_optimizer.step()
        if zero_grad:
            self.zero_grad()

    @torch.no_grad()
    def step(self, closure=None):
        if closure is None:
            raise RuntimeError("SAM requires a closure for step()")
        closure = torch.enable_grad()(closure)
        self.first_step(zero_grad=True)
        closure()
        self.second_step()

    def zero_grad(self, set_to_none: bool = False) -> None:
        self.base_optimizer.zero_grad(set_to_none=set_to_none)

    def state_dict(self):
        return {
            "base_optimizer": self.base_optimizer.state_dict(),
            "sam_optimizer": super().state_dict(),
        }

    def load_state_dict(self, state_dict):
        super().load_state_dict(state_dict["sam_optimizer"])
        self.base_optimizer.load_state_dict(state_dict["base_optimizer"])
        self.param_groups = self.base_optimizer.param_groups

    def _grad_norm(self) -> torch.Tensor:
        shared_device = self.param_groups[0]["params"][0].device
        norms = []
        for group in self.param_groups:
            adaptive = group.get("adaptive", False)
            for param in group["params"]:
                if param.grad is None:
                    continue
                grad = param.grad
                if adaptive:
                    grad = grad * param.abs()
                norms.append(torch.norm(grad, p=2).to(shared_device))
        if not norms:
            return torch.tensor(0.0, device=shared_device)
        return torch.norm(torch.stack(norms), p=2)


def build_optimizer(model: torch.nn.Module, optimizer_cfg: dict[str, Any]) -> tuple[torch.optim.Optimizer, bool]:
    optimizer_name = optimizer_cfg["name"].lower()
    lr = optimizer_cfg["lr"]
    weight_decay = optimizer_cfg.get("weight_decay", 0.0)

    if optimizer_name == "sgd":
        return (
            torch.optim.SGD(
                model.parameters(),
                lr=lr,
                momentum=optimizer_cfg.get("momentum", 0.0),
                weight_decay=weight_decay,
                nesterov=bool(optimizer_cfg.get("nesterov", False)),
            ),
            False,
        )
    if optimizer_name == "adamw":
        return (
            torch.optim.AdamW(
                model.parameters(),
                lr=lr,
                betas=tuple(optimizer_cfg.get("betas", [0.9, 0.999])),
                weight_decay=weight_decay,
            ),
            False,
        )
    if optimizer_name == "sam_sgd":
        return (
            SAM(
                model.parameters(),
                base_optimizer_cls=torch.optim.SGD,
                lr=lr,
                momentum=optimizer_cfg.get("momentum", 0.0),
                weight_decay=weight_decay,
                nesterov=bool(optimizer_cfg.get("nesterov", False)),
                rho=float(optimizer_cfg.get("rho", 0.05)),
                adaptive=bool(optimizer_cfg.get("adaptive", False)),
            ),
            True,
        )
    if optimizer_name == "sam_adamw":
        return (
            SAM(
                model.parameters(),
                base_optimizer_cls=torch.optim.AdamW,
                lr=lr,
                betas=tuple(optimizer_cfg.get("betas", [0.9, 0.999])),
                weight_decay=weight_decay,
                rho=float(optimizer_cfg.get("rho", 0.05)),
                adaptive=bool(optimizer_cfg.get("adaptive", False)),
            ),
            True,
        )
    raise ValueError(f"Unsupported optimizer '{optimizer_cfg['name']}'")
