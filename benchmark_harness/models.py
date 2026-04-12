from __future__ import annotations

import torch
import torch.nn as nn
import torch.nn.functional as F
from torchvision.models import (
    EfficientNet_B0_Weights,
    EfficientNet_B3_Weights,
    EfficientNet_V2_S_Weights,
    efficientnet_b0,
    efficientnet_b3,
    efficientnet_v2_s,
)
from torchvision.models.resnet import BasicBlock, ResNet


class CIFARResNet(ResNet):
    def __init__(self, num_classes: int) -> None:
        super().__init__(block=BasicBlock, layers=[2, 2, 2, 2], num_classes=num_classes)
        self.conv1 = nn.Conv2d(3, 64, kernel_size=3, stride=1, padding=1, bias=False)
        self.maxpool = nn.Identity()


class WideBasicBlock(nn.Module):
    def __init__(self, in_channels: int, out_channels: int, stride: int, dropout: float) -> None:
        super().__init__()
        self.bn1 = nn.BatchNorm2d(in_channels)
        self.conv1 = nn.Conv2d(in_channels, out_channels, kernel_size=3, padding=1, bias=False)
        self.dropout = nn.Dropout(p=dropout) if dropout > 0 else nn.Identity()
        self.bn2 = nn.BatchNorm2d(out_channels)
        self.conv2 = nn.Conv2d(
            out_channels,
            out_channels,
            kernel_size=3,
            stride=stride,
            padding=1,
            bias=False,
        )
        self.shortcut = nn.Identity()
        if stride != 1 or in_channels != out_channels:
            self.shortcut = nn.Conv2d(
                in_channels,
                out_channels,
                kernel_size=1,
                stride=stride,
                bias=False,
            )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        out = self.conv1(F.relu(self.bn1(x), inplace=True))
        out = self.dropout(out)
        out = self.conv2(F.relu(self.bn2(out), inplace=True))
        return out + self.shortcut(x)


class CIFARWideResNet(nn.Module):
    def __init__(self, depth: int, widen_factor: int, dropout: float, num_classes: int) -> None:
        super().__init__()
        if (depth - 4) % 6 != 0:
            raise ValueError("WideResNet depth must satisfy (depth - 4) % 6 == 0")
        blocks_per_stage = (depth - 4) // 6
        widths = [16, 16 * widen_factor, 32 * widen_factor, 64 * widen_factor]

        self.stem = nn.Conv2d(3, widths[0], kernel_size=3, stride=1, padding=1, bias=False)
        self.stage1 = self._make_stage(widths[0], widths[1], blocks_per_stage, stride=1, dropout=dropout)
        self.stage2 = self._make_stage(widths[1], widths[2], blocks_per_stage, stride=2, dropout=dropout)
        self.stage3 = self._make_stage(widths[2], widths[3], blocks_per_stage, stride=2, dropout=dropout)
        self.bn = nn.BatchNorm2d(widths[3])
        self.fc = nn.Linear(widths[3], num_classes)

        for module in self.modules():
            if isinstance(module, nn.Conv2d):
                nn.init.kaiming_normal_(module.weight, mode="fan_out", nonlinearity="relu")
            elif isinstance(module, nn.BatchNorm2d):
                nn.init.constant_(module.weight, 1.0)
                nn.init.constant_(module.bias, 0.0)
            elif isinstance(module, nn.Linear):
                nn.init.constant_(module.bias, 0.0)

    @staticmethod
    def _make_stage(
        in_channels: int,
        out_channels: int,
        blocks: int,
        stride: int,
        dropout: float,
    ) -> nn.Sequential:
        layers: list[nn.Module] = []
        for block_idx in range(blocks):
            layers.append(
                WideBasicBlock(
                    in_channels=in_channels if block_idx == 0 else out_channels,
                    out_channels=out_channels,
                    stride=stride if block_idx == 0 else 1,
                    dropout=dropout,
                )
            )
        return nn.Sequential(*layers)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        out = self.stem(x)
        out = self.stage1(out)
        out = self.stage2(out)
        out = self.stage3(out)
        out = F.relu(self.bn(out), inplace=True)
        out = F.adaptive_avg_pool2d(out, 1)
        out = torch.flatten(out, 1)
        return self.fc(out)


class ASTLikeModel(nn.Module):
    def __init__(
        self,
        num_classes: int,
        input_shape: tuple[int, int, int],
        embed_dim: int,
        depth: int,
        num_heads: int,
        mlp_ratio: float = 4.0,
        dropout: float = 0.1,
        patch_size: tuple[int, int] = (16, 16),
    ) -> None:
        super().__init__()
        channels, height, width = input_shape
        patch_h, patch_w = patch_size
        self.patch_embed = nn.Conv2d(
            channels,
            embed_dim,
            kernel_size=(patch_h, patch_w),
            stride=(patch_h, patch_w),
        )
        num_patches = (height // patch_h) * (width // patch_w)
        encoder_layer = nn.TransformerEncoderLayer(
            d_model=embed_dim,
            nhead=num_heads,
            dim_feedforward=int(embed_dim * mlp_ratio),
            dropout=dropout,
            activation="gelu",
            batch_first=True,
            norm_first=True,
        )
        self.cls_token = nn.Parameter(torch.zeros(1, 1, embed_dim))
        self.pos_embed = nn.Parameter(torch.zeros(1, num_patches + 1, embed_dim))
        self.encoder = nn.TransformerEncoder(encoder_layer, num_layers=depth)
        self.norm = nn.LayerNorm(embed_dim)
        self.head = nn.Linear(embed_dim, num_classes)
        self.dropout = nn.Dropout(dropout)

        nn.init.trunc_normal_(self.pos_embed, std=0.02)
        nn.init.trunc_normal_(self.cls_token, std=0.02)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        tokens = self.patch_embed(x)
        tokens = tokens.flatten(2).transpose(1, 2)
        cls_token = self.cls_token.expand(tokens.size(0), -1, -1)
        tokens = torch.cat([cls_token, tokens], dim=1)
        tokens = self.dropout(tokens + self.pos_embed[:, : tokens.size(1)])
        encoded = self.encoder(tokens)
        return self.head(self.norm(encoded[:, 0]))


class GeMPool2d(nn.Module):
    def __init__(self, p: float = 3.0, eps: float = 1e-6) -> None:
        super().__init__()
        self.p = nn.Parameter(torch.ones(1) * p)
        self.eps = eps

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return F.avg_pool2d(x.clamp_min(self.eps).pow(self.p), kernel_size=(x.size(-2), x.size(-1))).pow(1.0 / self.p)


class EfficientNetAudioClassifier(nn.Module):
    def __init__(self, variant: str, num_classes: int, pooling: str = "gem", dropout: float | None = None, pretrained: bool = True) -> None:
        super().__init__()
        variant = variant.lower()
        if variant == "b0":
            backbone = efficientnet_b0(weights=EfficientNet_B0_Weights.DEFAULT if pretrained else None)
        elif variant == "b3":
            backbone = efficientnet_b3(weights=EfficientNet_B3_Weights.DEFAULT if pretrained else None)
        elif variant in {"v2_s", "v2-s"}:
            backbone = efficientnet_v2_s(weights=EfficientNet_V2_S_Weights.DEFAULT if pretrained else None)
        else:
            raise ValueError(f"Unsupported EfficientNet variant '{variant}'")

        self.features = backbone.features
        in_features = backbone.classifier[1].in_features
        self.pool = GeMPool2d() if pooling.lower() == "gem" else nn.AdaptiveAvgPool2d(1)
        head_dropout = backbone.classifier[0].p if dropout is None else float(dropout)
        self.dropout = nn.Dropout(head_dropout)
        self.classifier = nn.Linear(in_features, num_classes)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        if x.size(1) == 1:
            x = x.repeat(1, 3, 1, 1)
        features = self.features(x)
        pooled = self.pool(features)
        pooled = torch.flatten(pooled, 1)
        return self.classifier(self.dropout(pooled))


def build_model(method_manifest: dict, num_classes: int, input_shape: tuple[int, int, int] | None = None) -> nn.Module:
    model_cfg = method_manifest["model"]
    model_name = model_cfg["name"].lower()
    resolved_input_shape = input_shape or tuple(model_cfg.get("input_shape", method_manifest.get("input_shape_override", [1, 128, 512])))

    if model_name == "resnet18":
        return CIFARResNet(num_classes=num_classes)
    if model_name == "wideresnet":
        return CIFARWideResNet(
            depth=int(model_cfg.get("depth", 28)),
            widen_factor=int(model_cfg.get("widen_factor", 10)),
            dropout=float(model_cfg.get("dropout", 0.0)),
            num_classes=num_classes,
        )
    if model_name in {"ast", "htsat", "beats"}:
        # NOTE: ast, htsat, and beats currently share the same ASTLikeModel
        # (vanilla ViT on spectrograms) with different default hyperparameters.
        # This means experiments comparing these three are hyperparameter
        # comparisons, NOT true architecture comparisons.
        # To run genuine architecture ablations:
        #   - HTS-AT requires hierarchical token-semantic attention (not implemented)
        #   - BEATs requires loading self-supervised pretrained weights (not implemented)
        # Treat results accordingly until dedicated implementations are added.
        defaults = {
            "ast":   {"embed_dim": 768, "depth": 8,  "num_heads": 12, "patch_size": (16, 16)},
            "htsat": {"embed_dim": 384, "depth": 6,  "num_heads": 6,  "patch_size": (8, 16)},
            "beats": {"embed_dim": 768, "depth": 10, "num_heads": 12, "patch_size": (16, 16)},
        }
        d = defaults[model_name]
        return ASTLikeModel(
            num_classes=num_classes,
            input_shape=resolved_input_shape,
            embed_dim=int(model_cfg.get("embed_dim", d["embed_dim"])),
            depth=int(model_cfg.get("depth", d["depth"])),
            num_heads=int(model_cfg.get("num_heads", d["num_heads"])),
            dropout=float(model_cfg.get("dropout", 0.1)),
            patch_size=tuple(model_cfg.get("patch_size", d["patch_size"])),
        )
    if model_name in {"efficientnet", "efficientnet_b0", "efficientnet_b3", "efficientnet_v2_s"}:
        variant = model_cfg.get("variant")
        if not variant:
            if model_name == "efficientnet_b0":
                variant = "b0"
            elif model_name == "efficientnet_b3":
                variant = "b3"
            elif model_name == "efficientnet_v2_s":
                variant = "v2_s"
            else:
                variant = "b0"
        return EfficientNetAudioClassifier(
            variant=str(variant),
            num_classes=num_classes,
            pooling=str(model_cfg.get("pooling", "gem")),
            dropout=model_cfg.get("dropout"),
            pretrained=bool(model_cfg.get("pretrained", True)),
        )
    raise ValueError(f"Unsupported model '{model_name}' in harness")
