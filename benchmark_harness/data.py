from __future__ import annotations

import csv
import hashlib
from ast import literal_eval
from pathlib import Path
from typing import Any

import torch
from torch.utils.data import DataLoader, Dataset, Subset, random_split
from torchvision import datasets, transforms


def _build_image_transforms(dataset_manifest: dict, train: bool, method_manifest: dict):
    normalize = transforms.Normalize(
        mean=dataset_manifest["normalization"]["mean"],
        std=dataset_manifest["normalization"]["std"],
    )

    ops = []
    augmentations = set(method_manifest.get("augmentations", []))
    if train and "random_crop_32_pad_4" in augmentations:
        ops.append(transforms.RandomCrop(32, padding=4))
    if train and "random_horizontal_flip" in augmentations:
        ops.append(transforms.RandomHorizontalFlip())
    if train and "randaugment" in augmentations:
        ops.append(transforms.RandAugment())
    ops.extend([transforms.ToTensor(), normalize])
    if train and "random_erasing" in augmentations:
        ops.append(transforms.RandomErasing(p=0.25, scale=(0.02, 0.2), ratio=(0.3, 3.3)))
    return transforms.Compose(ops)


def _resolve_dataset_root(dataset_manifest: dict, data_root: str) -> Path:
    dataset_root = Path(data_root)
    if dataset_root.exists():
        nested = dataset_root / "birdclef-2026"
        if (nested / "train.csv").exists():
            return nested
        return dataset_root
    storage_cfg = dataset_manifest.get("storage", {})
    mount_hint = storage_cfg.get("mount_hint")
    if mount_hint:
        mount_path = Path(mount_hint)
        if mount_path.exists():
            nested = mount_path / "birdclef-2026"
            if (nested / "train.csv").exists():
                return nested
            return mount_path
    dataset_root.mkdir(parents=True, exist_ok=True)
    return dataset_root


def _parse_secondary_labels(raw: str | None) -> list[str]:
    if not raw or raw in {"[]", ""}:
        return []
    try:
        parsed = literal_eval(raw)
        if isinstance(parsed, list):
            return [str(item) for item in parsed if str(item)]
    except (SyntaxError, ValueError):
        pass
    cleaned = raw.replace("|", " ").replace(",", " ").replace(";", " ")
    return [token.strip() for token in cleaned.split() if token.strip()]


def _stable_fold(group_key: str, num_folds: int) -> int:
    digest = hashlib.md5(group_key.encode("utf-8")).hexdigest()
    return int(digest[:8], 16) % num_folds


def _discover_label_column(fieldnames: list[str]) -> str:
    for candidate in ("primary_label", "label", "species", "target", "scientific_name"):
        if candidate in fieldnames:
            return candidate
    raise ValueError("Could not infer BirdCLEF label column from metadata")


def _discover_audio_column(fieldnames: list[str]) -> str:
    for candidate in ("filepath", "path", "filename", "file_name"):
        if candidate in fieldnames:
            return candidate
    raise ValueError("Could not infer BirdCLEF audio path column from metadata")


def _discover_group_column(fieldnames: list[str]) -> str | None:
    for candidate in ("recordist", "author", "source_id", "recording_id", "license", "site"):
        if candidate in fieldnames:
            return candidate
    return None


def _load_soundscape_labels(root: Path, label_to_idx: dict[str, int], num_classes: int) -> list[dict[str, Any]]:
    """Load expert-labeled train_soundscapes segments as training examples.

    These segments share recording locations with the test set and provide
    multi-label annotations — they are the highest domain-match training data.
    """
    labels_path = root / "train_soundscapes_labels.csv"
    if not labels_path.exists():
        return []

    soundscape_dir = root / "train_soundscapes"
    if not soundscape_dir.exists():
        return []

    examples: list[dict[str, Any]] = []
    with labels_path.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            filename = row.get("filename", "")
            start_sec = float(row.get("start", 0))
            end_sec = float(row.get("end", 5))
            raw_labels = row.get("primary_label", "")

            audio_path = soundscape_dir / filename
            if not audio_path.exists():
                continue

            target = torch.zeros(num_classes, dtype=torch.float32)
            species_list = [s.strip() for s in raw_labels.split(";") if s.strip()]
            for sp in species_list:
                if sp in label_to_idx:
                    target[label_to_idx[sp]] = 1.0

            # Group by soundscape filename (prevents same-site leakage across folds)
            group_key = filename.split(".")[0]

            examples.append(
                {
                    "audio_path": audio_path,
                    "target": target,
                    "group": group_key,
                    "start_sec": start_sec,
                    "end_sec": end_sec,
                    "source": "train_soundscapes",
                }
            )
    return examples


class BirdCLEFAudioDataset(Dataset):
    def __init__(
        self,
        dataset_manifest: dict[str, Any],
        method_manifest: dict[str, Any],
        root: Path,
        split: str,
        fold_index: int,
        num_folds: int,
        train_mode: bool,
    ) -> None:
        try:
            import torchaudio
        except ImportError as exc:
            raise ImportError("BirdCLEF audio loading requires torchaudio>=2.2") from exc

        self.torchaudio = torchaudio
        self.dataset_manifest = dataset_manifest
        self.method_manifest = method_manifest
        self.root = root
        self.split = split
        self.train_mode = train_mode

        metadata_path = root / "train.csv"
        sample_submission_path = root / "sample_submission.csv"
        if not metadata_path.exists():
            raise FileNotFoundError(f"Missing BirdCLEF metadata: {metadata_path}")
        if not sample_submission_path.exists():
            raise FileNotFoundError(f"Missing BirdCLEF sample submission: {sample_submission_path}")

        with sample_submission_path.open("r", encoding="utf-8", newline="") as handle:
            reader = csv.reader(handle)
            header = next(reader)
        self.label_to_idx = {label: idx for idx, label in enumerate(header[1:])}
        self.num_classes = len(self.label_to_idx)

        with metadata_path.open("r", encoding="utf-8", newline="") as handle:
            reader = csv.DictReader(handle)
            rows = list(reader)
            if reader.fieldnames is None:
                raise ValueError("BirdCLEF metadata is missing headers")
            fieldnames = reader.fieldnames

        label_column = _discover_label_column(fieldnames)
        audio_column = _discover_audio_column(fieldnames)
        group_column = _discover_group_column(fieldnames)

        # --- train_audio examples (from train.csv) ---
        examples = []
        for row in rows:
            rel_path = row[audio_column]
            audio_path = self._resolve_audio_path(rel_path)
            primary_label = row[label_column]
            target = torch.zeros(self.num_classes, dtype=torch.float32)
            if primary_label in self.label_to_idx:
                target[self.label_to_idx[primary_label]] = 1.0
            for secondary_label in _parse_secondary_labels(row.get("secondary_labels")):
                if secondary_label in self.label_to_idx:
                    target[self.label_to_idx[secondary_label]] = 1.0
            group_key = str(row.get(group_column) or Path(rel_path).stem)
            examples.append(
                {
                    "audio_path": audio_path,
                    "target": target,
                    "group": group_key,
                    "start_sec": None,
                    "end_sec": None,
                    "source": "train_audio",
                }
            )

        # --- train_soundscapes examples (from train_soundscapes_labels.csv) ---
        include_soundscapes = bool(method_manifest["training"].get("include_soundscapes", True))
        if include_soundscapes:
            soundscape_examples = _load_soundscape_labels(root, self.label_to_idx, self.num_classes)
            examples.extend(soundscape_examples)

        if split in {"train", "validation"}:
            selected = [
                example
                for example in examples
                if (_stable_fold(example["group"], num_folds) == fold_index) == (split == "validation")
            ]
        else:
            selected = examples
        if not selected:
            raise ValueError(f"No BirdCLEF examples selected for split '{split}'")
        self.examples = selected

        training_cfg = method_manifest["training"]
        self.sample_rate = int(training_cfg.get("sample_rate", 32000))
        self.clip_seconds = float(training_cfg.get("segment_seconds", 5.0))
        self.clip_samples = int(self.sample_rate * self.clip_seconds)
        self.n_mels = int(dataset_manifest["input_shape"][1])
        self.time_bins = int(dataset_manifest["input_shape"][2])
        self.augmentations = set(method_manifest.get("augmentations", []))

        self.mel_transform = torchaudio.transforms.MelSpectrogram(
            sample_rate=self.sample_rate,
            n_fft=2048,
            hop_length=512,
            n_mels=self.n_mels,
            f_min=20,
            f_max=min(16000, self.sample_rate // 2),
        )
        self.db_transform = torchaudio.transforms.AmplitudeToDB(stype="power")
        self.time_mask = torchaudio.transforms.TimeMasking(time_mask_param=max(8, self.time_bins // 16))
        self.freq_mask = torchaudio.transforms.FrequencyMasking(freq_mask_param=max(4, self.n_mels // 16))
        self.normalize_mean = torch.tensor(dataset_manifest["normalization"]["mean"], dtype=torch.float32).view(-1, 1, 1)
        self.normalize_std = torch.tensor(dataset_manifest["normalization"]["std"], dtype=torch.float32).view(-1, 1, 1)

    def _resolve_audio_path(self, relative_path: str) -> Path:
        candidate = self.root / relative_path
        if candidate.exists():
            return candidate
        train_audio_root = self.root / "train_audio"
        candidate = train_audio_root / relative_path
        if candidate.exists():
            return candidate
        candidate = train_audio_root / Path(relative_path).name
        if candidate.exists():
            return candidate
        return self.root / relative_path

    def __len__(self) -> int:
        return len(self.examples)

    def _load_waveform(self, path: Path) -> torch.Tensor:
        waveform, sample_rate = self.torchaudio.load(path)
        if waveform.size(0) > 1:
            waveform = waveform.mean(dim=0, keepdim=True)
        if sample_rate != self.sample_rate:
            waveform = self.torchaudio.functional.resample(waveform, sample_rate, self.sample_rate)
        return waveform

    def _crop_or_pad(self, waveform: torch.Tensor) -> torch.Tensor:
        num_samples = waveform.size(-1)
        if num_samples < self.clip_samples:
            padded = torch.zeros((1, self.clip_samples), dtype=waveform.dtype)
            padded[:, :num_samples] = waveform
            return padded
        if num_samples == self.clip_samples:
            return waveform
        if self.train_mode:
            start = torch.randint(0, num_samples - self.clip_samples + 1, (1,)).item()
        else:
            start = max(0, (num_samples - self.clip_samples) // 2)
        return waveform[:, start : start + self.clip_samples]

    def _augment_waveform(self, waveform: torch.Tensor) -> torch.Tensor:
        if self.train_mode and "time_shift" in self.augmentations:
            shift = torch.randint(0, max(1, waveform.size(-1) // 10), (1,)).item()
            waveform = torch.roll(waveform, shifts=shift, dims=-1)
        if self.train_mode and "random_gain" in self.augmentations:
            gain = torch.empty(1).uniform_(0.8, 1.2).item()
            waveform = waveform * gain
        if self.train_mode and "background_mix" in self.augmentations:
            waveform = waveform + 0.003 * torch.randn_like(waveform)
        return waveform

    def _to_logmel(self, waveform: torch.Tensor) -> torch.Tensor:
        features = self.mel_transform(waveform)
        features = self.db_transform(features)
        if features.size(-1) < self.time_bins:
            pad = self.time_bins - features.size(-1)
            features = torch.nn.functional.pad(features, (0, pad))
        elif features.size(-1) > self.time_bins:
            features = features[..., : self.time_bins]
        if self.train_mode and "specaugment" in self.augmentations:
            features = self.time_mask(features)
            features = self.freq_mask(features)
        return (features - self.normalize_mean) / self.normalize_std

    def _extract_segment(self, waveform: torch.Tensor, start_sec: float | None, end_sec: float | None) -> torch.Tensor:
        """Extract a specific time segment from a soundscape waveform.

        For train_soundscapes entries that have start/end annotations,
        extract exactly that window instead of random cropping.
        """
        if start_sec is None or end_sec is None:
            return waveform
        start_sample = int(start_sec * self.sample_rate)
        end_sample = int(end_sec * self.sample_rate)
        start_sample = max(0, min(start_sample, waveform.size(-1)))
        end_sample = max(start_sample, min(end_sample, waveform.size(-1)))
        return waveform[:, start_sample:end_sample]

    def __getitem__(self, index: int) -> tuple[torch.Tensor, torch.Tensor]:
        example = self.examples[index]
        waveform = self._load_waveform(example["audio_path"])
        # For soundscape segments, extract the annotated time window first
        waveform = self._extract_segment(waveform, example.get("start_sec"), example.get("end_sec"))
        waveform = self._crop_or_pad(waveform)
        waveform = self._augment_waveform(waveform)
        return self._to_logmel(waveform), example["target"].clone()


def _build_image_dataloaders(
    dataset_manifest: dict,
    method_manifest: dict,
    seed: int,
    batch_size: int,
    num_workers: int,
    data_root: Path,
) -> tuple[DataLoader, DataLoader, DataLoader]:
    dataset_id = dataset_manifest["dataset_id"].lower()
    if dataset_id == "cifar10":
        dataset_cls = datasets.CIFAR10
    elif dataset_id == "cifar100":
        dataset_cls = datasets.CIFAR100
    else:
        raise ValueError(f"Unsupported dataset '{dataset_id}'")

    train_dataset = dataset_cls(
        root=str(data_root),
        train=True,
        download=True,
        transform=_build_image_transforms(dataset_manifest, train=True, method_manifest=method_manifest),
    )
    val_dataset = dataset_cls(
        root=str(data_root),
        train=True,
        download=True,
        transform=_build_image_transforms(dataset_manifest, train=False, method_manifest=method_manifest),
    )
    test_dataset = dataset_cls(
        root=str(data_root),
        train=False,
        download=True,
        transform=_build_image_transforms(dataset_manifest, train=False, method_manifest=method_manifest),
    )

    generator = torch.Generator().manual_seed(seed)
    train_size = dataset_manifest["splits"]["train"]
    val_size = dataset_manifest["splits"]["validation"]
    train_subset, _ = random_split(train_dataset, [train_size, val_size], generator=generator)
    _, val_subset = random_split(val_dataset, [train_size, val_size], generator=generator)

    loader_kwargs = {
        "batch_size": batch_size,
        "num_workers": num_workers,
        "pin_memory": torch.cuda.is_available(),
    }
    return (
        DataLoader(train_subset, shuffle=True, **loader_kwargs),
        DataLoader(val_subset, shuffle=False, **loader_kwargs),
        DataLoader(test_dataset, shuffle=False, **loader_kwargs),
    )


def _build_birdclef_dataloaders(
    dataset_manifest: dict,
    method_manifest: dict,
    seed: int,
    batch_size: int,
    num_workers: int,
    data_root: Path,
) -> tuple[DataLoader, DataLoader, DataLoader]:
    fold_index = int(method_manifest["training"].get("fold_index", 0))
    num_folds = int(method_manifest["training"].get("num_folds", 5))

    train_dataset = BirdCLEFAudioDataset(
        dataset_manifest=dataset_manifest,
        method_manifest=method_manifest,
        root=data_root,
        split="train",
        fold_index=fold_index,
        num_folds=num_folds,
        train_mode=True,
    )
    val_dataset = BirdCLEFAudioDataset(
        dataset_manifest=dataset_manifest,
        method_manifest=method_manifest,
        root=data_root,
        split="validation",
        fold_index=fold_index,
        num_folds=num_folds,
        train_mode=False,
    )

    loader_kwargs = {
        "batch_size": batch_size,
        "num_workers": num_workers,
        "pin_memory": torch.cuda.is_available(),
    }
    train_loader = DataLoader(train_dataset, shuffle=True, **loader_kwargs)
    val_loader = DataLoader(val_dataset, shuffle=False, **loader_kwargs)
    return train_loader, val_loader, val_loader


def build_dataloaders(
    dataset_manifest: dict,
    method_manifest: dict,
    seed: int,
    batch_size: int,
    num_workers: int,
    data_root: str,
) -> tuple[DataLoader, DataLoader, DataLoader]:
    dataset_root = _resolve_dataset_root(dataset_manifest, data_root)
    dataset_family = dataset_manifest["dataset_family"].lower()
    if dataset_family == "torchvision_cifar":
        return _build_image_dataloaders(
            dataset_manifest=dataset_manifest,
            method_manifest=method_manifest,
            seed=seed,
            batch_size=batch_size,
            num_workers=num_workers,
            data_root=dataset_root,
        )
    if dataset_family == "kaggle_birdclef_soundscape":
        return _build_birdclef_dataloaders(
            dataset_manifest=dataset_manifest,
            method_manifest=method_manifest,
            seed=seed,
            batch_size=batch_size,
            num_workers=num_workers,
            data_root=dataset_root,
        )
    raise ValueError(f"Unsupported dataset family '{dataset_family}'")
