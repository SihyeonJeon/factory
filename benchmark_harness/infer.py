from __future__ import annotations

import argparse
import csv
from pathlib import Path

import torch

from .manifests import load_json, resolve_num_classes, resolve_repo_path
from .models import build_model
from .utils import get_device


def _resolve_dataset_root(dataset_manifest: dict, data_root: str) -> Path:
    dataset_root = Path(data_root)
    if dataset_root.exists():
        nested = dataset_root / "birdclef-2026"
        if (nested / "train.csv").exists():
            return nested
        return dataset_root
    mount_hint = dataset_manifest.get("storage", {}).get("mount_hint")
    if mount_hint:
        mount_path = Path(mount_hint)
        if mount_path.exists():
            nested = mount_path / "birdclef-2026"
            if (nested / "train.csv").exists():
                return nested
            return mount_path
    raise FileNotFoundError(f"Could not resolve dataset root from '{data_root}'")


def _build_feature_extractor(dataset_manifest: dict, training_cfg: dict):
    try:
        import torchaudio
    except ImportError as exc:
        raise ImportError("BirdCLEF inference requires torchaudio>=2.2") from exc

    sample_rate = int(training_cfg.get("sample_rate", 32000))
    n_mels = int(dataset_manifest["input_shape"][1])
    time_bins = int(dataset_manifest["input_shape"][2])
    mel_transform = torchaudio.transforms.MelSpectrogram(
        sample_rate=sample_rate,
        n_fft=2048,
        hop_length=512,
        n_mels=n_mels,
        f_min=20,
        f_max=min(16000, sample_rate // 2),
    )
    db_transform = torchaudio.transforms.AmplitudeToDB(stype="power")
    normalize_mean = torch.tensor(dataset_manifest["normalization"]["mean"], dtype=torch.float32).view(-1, 1, 1)
    normalize_std = torch.tensor(dataset_manifest["normalization"]["std"], dtype=torch.float32).view(-1, 1, 1)
    return torchaudio, sample_rate, time_bins, mel_transform, db_transform, normalize_mean, normalize_std


def _waveform_to_feature(
    waveform: torch.Tensor,
    *,
    time_bins: int,
    mel_transform,
    db_transform,
    normalize_mean: torch.Tensor,
    normalize_std: torch.Tensor,
) -> torch.Tensor:
    features = mel_transform(waveform)
    features = db_transform(features)
    if features.size(-1) < time_bins:
        features = torch.nn.functional.pad(features, (0, time_bins - features.size(-1)))
    elif features.size(-1) > time_bins:
        features = features[..., :time_bins]
    return (features - normalize_mean) / normalize_std


def _parse_row_id(row_id: str) -> tuple[str, float | None]:
    parts = row_id.split("_")
    if parts and parts[-1].isdigit():
        return "_".join(parts[:-1]), float(parts[-1])
    return row_id, None


def _resolve_soundscape_path(soundscape_root: Path, soundscape_id: str) -> Path:
    direct = soundscape_root / f"{soundscape_id}.ogg"
    if direct.exists():
        return direct
    for extension in (".ogg", ".wav", ".mp3", ".flac"):
        matches = list(soundscape_root.glob(f"{soundscape_id}*{extension}"))
        if matches:
            return matches[0]
    raise FileNotFoundError(f"Could not resolve soundscape file for id '{soundscape_id}' in {soundscape_root}")


def _extract_window(waveform: torch.Tensor, sample_rate: int, clip_seconds: float, end_seconds: float | None) -> torch.Tensor:
    clip_samples = int(sample_rate * clip_seconds)
    if end_seconds is None:
        start = max(0, (waveform.size(-1) - clip_samples) // 2)
    else:
        end_sample = int(end_seconds * sample_rate)
        start = max(0, end_sample - clip_samples)
    window = waveform[:, start : start + clip_samples]
    if window.size(-1) < clip_samples:
        padded = torch.zeros((1, clip_samples), dtype=waveform.dtype)
        padded[:, : window.size(-1)] = window
        return padded
    return window


def generate_submission_from_manifests(
    run_manifest_path: str,
    data_root: str,
    output_path: str,
    soundscape_split: str = "test_soundscapes",
) -> Path:
    run_manifest = load_json(run_manifest_path)
    dataset_manifest = load_json(run_manifest["dataset_manifest"])
    method_manifest = load_json(run_manifest["method_manifest"])
    training_log = load_json(run_manifest["artifacts"]["training_log"])
    num_classes = resolve_num_classes(dataset_manifest)

    checkpoint_path = training_log["checkpoint_path"]
    if not checkpoint_path:
        raise ValueError("Training log does not contain a checkpoint path")

    dataset_root = _resolve_dataset_root(dataset_manifest, data_root)
    sample_submission_path = dataset_root / "sample_submission.csv"
    soundscape_root = dataset_root / soundscape_split
    if not sample_submission_path.exists():
        raise FileNotFoundError(f"Missing sample submission file: {sample_submission_path}")
    if not soundscape_root.exists():
        raise FileNotFoundError(f"Missing soundscape directory: {soundscape_root}")

    device = get_device()
    model = build_model(
        method_manifest,
        num_classes,
        input_shape=tuple(dataset_manifest["input_shape"]),
    ).to(device)
    checkpoint = torch.load(checkpoint_path, map_location=device)
    model.load_state_dict(checkpoint["model_state_dict"])
    model.eval()

    training_cfg = method_manifest["training"]
    clip_seconds = float(training_cfg.get("segment_seconds", 5.0))
    torchaudio, sample_rate, time_bins, mel_transform, db_transform, normalize_mean, normalize_std = _build_feature_extractor(
        dataset_manifest,
        training_cfg,
    )

    with sample_submission_path.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        fieldnames = reader.fieldnames or []
        if not fieldnames:
            raise ValueError("sample_submission.csv has no header")
        class_labels = fieldnames[1:]
        rows = list(reader)

    waveform_cache: dict[str, torch.Tensor] = {}
    output_rows: list[dict[str, str]] = []

    for row in rows:
        row_id = row[fieldnames[0]]
        soundscape_id, end_seconds = _parse_row_id(row_id)
        if soundscape_id not in waveform_cache:
            soundscape_path = _resolve_soundscape_path(soundscape_root, soundscape_id)
            waveform, source_sr = torchaudio.load(soundscape_path)
            if waveform.size(0) > 1:
                waveform = waveform.mean(dim=0, keepdim=True)
            if source_sr != sample_rate:
                waveform = torchaudio.functional.resample(waveform, source_sr, sample_rate)
            waveform_cache[soundscape_id] = waveform

        window = _extract_window(waveform_cache[soundscape_id], sample_rate, clip_seconds, end_seconds)
        feature = _waveform_to_feature(
            window,
            time_bins=time_bins,
            mel_transform=mel_transform,
            db_transform=db_transform,
            normalize_mean=normalize_mean,
            normalize_std=normalize_std,
        ).unsqueeze(0).to(device)
        with torch.no_grad():
            probs = torch.sigmoid(model(feature))[0].detach().cpu().tolist()

        output_row = {fieldnames[0]: row_id}
        output_row.update({label: f"{score:.8f}" for label, score in zip(class_labels, probs)})
        output_rows.append(output_row)

    output_file = resolve_repo_path(output_path)
    output_file.parent.mkdir(parents=True, exist_ok=True)
    with output_file.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(output_rows)
    return output_file


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate a BirdCLEF 2026 submission from a run manifest")
    parser.add_argument("--run-manifest", required=True)
    parser.add_argument("--data-root", default="data")
    parser.add_argument("--output", default="experiment_log/submission.csv")
    parser.add_argument("--soundscape-split", default="test_soundscapes")
    args = parser.parse_args()
    output_path = generate_submission_from_manifests(
        run_manifest_path=args.run_manifest,
        data_root=args.data_root,
        output_path=args.output,
        soundscape_split=args.soundscape_split,
    )
    print(output_path)


if __name__ == "__main__":
    main()
