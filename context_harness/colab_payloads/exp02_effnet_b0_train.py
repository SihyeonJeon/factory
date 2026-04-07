"""
EXP-02: EfficientNet-B0 + GeM Anchor Baseline (fold 0)
Method manifest: birdclef2026_effnet_b0_gem
Resolves: BLOCK-02

Run in Colab with A100 GPU + mounted Google Drive.
"""

# ═══════════════════════════════════════════
# CONFIG (edit these if paths differ)
# ═══════════════════════════════════════════
DATASET_ROOT = "/content/drive/MyDrive/Kaggle/birdclef-2026/birdclef-2026"
OUTPUT_DIR = "/content/drive/MyDrive/Kaggle/birdclef-2026/exp02_effnet_b0"
SEED = 3407
FOLD = 0
NUM_FOLDS = 5
EPOCHS = 20
BATCH_SIZE = 64
LR = 3e-4
WEIGHT_DECAY = 0.01
WARMUP_EPOCHS = 2
MIXUP_ALPHA = 0.15
SAMPLE_RATE = 32000
SEGMENT_SEC = 5
N_MELS = 128
N_FFT = 2048
HOP_LENGTH = 512
FMIN = 20
FMAX = 16000
NUM_WORKERS = 4
GIT_HASH = "PLACEHOLDER"

import os, json, time, datetime, random, warnings
warnings.filterwarnings("ignore")

import numpy as np
import pandas as pd
import torch
import torch.nn as nn
import torch.nn.functional as F
from torch.utils.data import Dataset, DataLoader
from torch.cuda.amp import autocast, GradScaler
from sklearn.model_selection import StratifiedGroupKFold
from sklearn.metrics import roc_auc_score
import torchaudio

# ═══════════════════════════════════════════
# REPRODUCIBILITY
# ═══════════════════════════════════════════
def set_seed(seed):
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False

set_seed(SEED)
os.makedirs(OUTPUT_DIR, exist_ok=True)

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(f"Device: {device}")
if torch.cuda.is_available():
    print(f"GPU: {torch.cuda.get_device_name(0)}, VRAM: {torch.cuda.get_device_properties(0).total_memory/1e9:.1f} GB")

# ═══════════════════════════════════════════
# DATA
# ═══════════════════════════════════════════
train_df = pd.read_csv(os.path.join(DATASET_ROOT, "train.csv"))
taxonomy_df = pd.read_csv(os.path.join(DATASET_ROOT, "taxonomy.csv"))
sample_sub = pd.read_csv(os.path.join(DATASET_ROOT, "sample_submission.csv"))

submission_species = [c for c in sample_sub.columns if c != "row_id"]
species_to_idx = {sp: i for i, sp in enumerate(submission_species)}
NUM_CLASSES = len(submission_species)
print(f"Classes: {NUM_CLASSES}, Train rows: {len(train_df)}")

# Group-aware split: StratifiedGroupKFold by primary_label, grouped by filename prefix (author/source)
train_df["group"] = train_df["filename"].apply(lambda x: x.split("/")[0] if "/" in str(x) else x.split("_")[0])
sgkf = StratifiedGroupKFold(n_splits=NUM_FOLDS, shuffle=True, random_state=SEED)
for fold_idx, (train_idx, val_idx) in enumerate(sgkf.split(train_df, train_df["primary_label"], train_df["group"])):
    if fold_idx == FOLD:
        break

train_data = train_df.iloc[train_idx].reset_index(drop=True)
val_data = train_df.iloc[val_idx].reset_index(drop=True)
print(f"Fold {FOLD}: train={len(train_data)}, val={len(val_data)}")

# ═══════════════════════════════════════════
# DATASET
# ═══════════════════════════════════════════
class BirdCLEFDataset(Dataset):
    def __init__(self, df, root, species_to_idx, num_classes, is_train=True):
        self.df = df
        self.root = root
        self.species_to_idx = species_to_idx
        self.num_classes = num_classes
        self.is_train = is_train
        self.target_len = SAMPLE_RATE * SEGMENT_SEC
        self.mel_spec = torchaudio.transforms.MelSpectrogram(
            sample_rate=SAMPLE_RATE, n_fft=N_FFT, hop_length=HOP_LENGTH,
            n_mels=N_MELS, f_min=FMIN, f_max=FMAX
        )

    def __len__(self):
        return len(self.df)

    def __getitem__(self, idx):
        row = self.df.iloc[idx]
        audio_path = os.path.join(self.root, "train_audio", row["filename"])

        try:
            waveform, sr = torchaudio.load(audio_path)
        except Exception:
            waveform = torch.zeros(1, self.target_len)
            sr = SAMPLE_RATE

        # Resample if needed
        if sr != SAMPLE_RATE:
            waveform = torchaudio.functional.resample(waveform, sr, SAMPLE_RATE)

        # Mono
        if waveform.shape[0] > 1:
            waveform = waveform.mean(dim=0, keepdim=True)

        # Random crop or pad to target length
        if waveform.shape[1] > self.target_len:
            if self.is_train:
                start = random.randint(0, waveform.shape[1] - self.target_len)
            else:
                start = 0
            waveform = waveform[:, start:start + self.target_len]
        elif waveform.shape[1] < self.target_len:
            pad = self.target_len - waveform.shape[1]
            waveform = F.pad(waveform, (0, pad))

        # Random gain augmentation (train only)
        if self.is_train:
            gain = random.uniform(0.8, 1.2)
            waveform = waveform * gain

        # Log-mel spectrogram
        mel = self.mel_spec(waveform)
        mel = torch.log(mel.clamp(min=1e-7))  # (1, n_mels, time)

        # SpecAugment (train only)
        if self.is_train:
            freq_mask = torchaudio.transforms.FrequencyMasking(freq_mask_param=20)
            time_mask = torchaudio.transforms.TimeMasking(time_mask_param=40)
            mel = freq_mask(mel)
            mel = time_mask(mel)

        # Label
        label = torch.zeros(self.num_classes, dtype=torch.float32)
        sp = row["primary_label"]
        if sp in self.species_to_idx:
            label[self.species_to_idx[sp]] = 1.0

        return mel, label

train_ds = BirdCLEFDataset(train_data, DATASET_ROOT, species_to_idx, NUM_CLASSES, is_train=True)
val_ds = BirdCLEFDataset(val_data, DATASET_ROOT, species_to_idx, NUM_CLASSES, is_train=False)
train_loader = DataLoader(train_ds, batch_size=BATCH_SIZE, shuffle=True, num_workers=NUM_WORKERS, pin_memory=True, drop_last=True)
val_loader = DataLoader(val_ds, batch_size=BATCH_SIZE, shuffle=False, num_workers=NUM_WORKERS, pin_memory=True)

# ═══════════════════════════════════════════
# MODEL
# ═══════════════════════════════════════════
from torchvision.models import efficientnet_b0

class GeMPool2d(nn.Module):
    def __init__(self, p=3.0, eps=1e-6):
        super().__init__()
        self.p = nn.Parameter(torch.ones(1) * p)
        self.eps = eps

    def forward(self, x):
        return F.avg_pool2d(
            x.clamp(min=self.eps).pow(self.p),
            kernel_size=(x.size(-2), x.size(-1))
        ).pow(1.0 / self.p)

class EfficientNetB0Audio(nn.Module):
    def __init__(self, num_classes):
        super().__init__()
        backbone = efficientnet_b0(weights="IMAGENET1K_V1")
        self.features = backbone.features
        in_features = backbone.classifier[1].in_features
        self.pool = GeMPool2d()
        self.dropout = nn.Dropout(0.3)
        self.classifier = nn.Linear(in_features, num_classes)

    def forward(self, x):
        if x.size(1) == 1:
            x = x.repeat(1, 3, 1, 1)
        x = self.features(x)
        x = self.pool(x)
        x = torch.flatten(x, 1)
        return self.classifier(self.dropout(x))

model = EfficientNetB0Audio(NUM_CLASSES).to(device)
print(f"Model params: {sum(p.numel() for p in model.parameters()):,}")

# EMA
class EMA:
    def __init__(self, model, decay=0.999):
        self.decay = decay
        self.shadow = {name: param.clone().detach() for name, param in model.named_parameters()}

    def update(self, model):
        for name, param in model.named_parameters():
            self.shadow[name].sub_((1 - self.decay) * (self.shadow[name] - param.data))

    def apply(self, model):
        self.backup = {name: param.clone() for name, param in model.named_parameters()}
        for name, param in model.named_parameters():
            param.data.copy_(self.shadow[name])

    def restore(self, model):
        for name, param in model.named_parameters():
            param.data.copy_(self.backup[name])

ema = EMA(model)

# ═══════════════════════════════════════════
# LOSS: BCE Focal
# ═══════════════════════════════════════════
class BCEFocalLoss(nn.Module):
    def __init__(self, gamma=2.0, alpha=0.25):
        super().__init__()
        self.gamma = gamma
        self.alpha = alpha

    def forward(self, logits, targets):
        bce = F.binary_cross_entropy_with_logits(logits, targets, reduction='none')
        pt = torch.exp(-bce)
        focal = self.alpha * (1 - pt) ** self.gamma * bce
        return focal.mean()

criterion = BCEFocalLoss()

# ═══════════════════════════════════════════
# OPTIMIZER + SCHEDULER
# ═══════════════════════════════════════════
optimizer = torch.optim.AdamW(model.parameters(), lr=LR, weight_decay=WEIGHT_DECAY, betas=(0.9, 0.999))
total_steps = EPOCHS * len(train_loader)
warmup_steps = WARMUP_EPOCHS * len(train_loader)

def lr_lambda(step):
    if step < warmup_steps:
        return step / max(warmup_steps, 1)
    progress = (step - warmup_steps) / max(total_steps - warmup_steps, 1)
    return 0.5 * (1 + np.cos(np.pi * progress))

scheduler = torch.optim.lr_scheduler.LambdaLR(optimizer, lr_lambda)
scaler = GradScaler()

# ═══════════════════════════════════════════
# MIXUP
# ═══════════════════════════════════════════
def mixup(x, y, alpha=0.15):
    lam = np.random.beta(alpha, alpha) if alpha > 0 else 1.0
    idx = torch.randperm(x.size(0)).to(x.device)
    x_mix = lam * x + (1 - lam) * x[idx]
    y_mix = lam * y + (1 - lam) * y[idx]
    return x_mix, y_mix

# ═══════════════════════════════════════════
# TRAINING LOOP
# ═══════════════════════════════════════════
best_auroc = 0.0
epoch_logs = []

print(f"\n{'='*60}")
print(f"EXP-02: EfficientNet-B0 + GeM | Fold {FOLD} | {EPOCHS} epochs")
print(f"{'='*60}\n")

for epoch in range(EPOCHS):
    t0 = time.time()
    model.train()
    running_loss = 0.0

    for batch_idx, (mel, labels) in enumerate(train_loader):
        mel, labels = mel.to(device), labels.to(device)
        mel, labels = mixup(mel, labels, MIXUP_ALPHA)

        optimizer.zero_grad()
        with autocast():
            logits = model(mel)
            loss = criterion(logits, labels)

        scaler.scale(loss).backward()
        scaler.step(optimizer)
        scaler.update()
        scheduler.step()
        ema.update(model)
        running_loss += loss.item()

    train_loss = running_loss / len(train_loader)

    # Validation with EMA weights
    ema.apply(model)
    model.eval()
    all_preds, all_labels = [], []

    with torch.no_grad():
        for mel, labels in val_loader:
            mel = mel.to(device)
            with autocast():
                logits = model(mel)
            probs = torch.sigmoid(logits).cpu().numpy()
            all_preds.append(probs)
            all_labels.append(labels.numpy())

    ema.restore(model)

    all_preds = np.concatenate(all_preds)
    all_labels = np.concatenate(all_labels)

    # Macro AUROC (skip classes with no positives — matches competition metric)
    per_class_auroc = []
    for c in range(NUM_CLASSES):
        if all_labels[:, c].sum() > 0:
            try:
                auc = roc_auc_score(all_labels[:, c], all_preds[:, c])
                per_class_auroc.append(auc)
            except ValueError:
                pass
    macro_auroc = np.mean(per_class_auroc) if per_class_auroc else 0.0

    elapsed = time.time() - t0
    current_lr = optimizer.param_groups[0]["lr"]
    gpu_mem = torch.cuda.max_memory_allocated() / 1e9 if torch.cuda.is_available() else 0

    log_entry = {
        "epoch": epoch + 1,
        "train_loss": round(train_loss, 5),
        "val_macro_auroc": round(macro_auroc, 5),
        "val_classes_scored": len(per_class_auroc),
        "lr": round(current_lr, 7),
        "gpu_mem_gb": round(gpu_mem, 2),
        "elapsed_sec": round(elapsed, 1)
    }
    epoch_logs.append(log_entry)

    print(f"Epoch {epoch+1:02d}/{EPOCHS} | loss={train_loss:.4f} | auroc={macro_auroc:.4f} ({len(per_class_auroc)} cls) | lr={current_lr:.6f} | mem={gpu_mem:.1f}GB | {elapsed:.0f}s")

    # Save best
    if macro_auroc > best_auroc:
        best_auroc = macro_auroc
        ema.apply(model)
        checkpoint = {
            "epoch": epoch + 1,
            "model_state": model.state_dict(),
            "optimizer_state": optimizer.state_dict(),
            "macro_auroc": macro_auroc,
            "seed": SEED,
            "fold": FOLD,
        }
        torch.save(checkpoint, os.path.join(OUTPUT_DIR, "best_model.pt"))
        ema.restore(model)
        print(f"  -> New best: {macro_auroc:.5f}")

    torch.cuda.reset_peak_memory_stats() if torch.cuda.is_available() else None

# ═══════════════════════════════════════════
# FINAL ARTIFACT
# ═══════════════════════════════════════════
artifact = {
    "exp_id": "EXP-02",
    "name": "EfficientNet-B0 + GeM Anchor Baseline (fold 0)",
    "method_manifest": "birdclef2026_effnet_b0_gem",
    "timestamp": datetime.datetime.now().isoformat(),
    "seed": SEED,
    "git_hash": GIT_HASH,
    "fold": FOLD,
    "epochs": EPOCHS,
    "batch_size": BATCH_SIZE,
    "best_macro_auroc": round(best_auroc, 5),
    "best_checkpoint": os.path.join(OUTPUT_DIR, "best_model.pt"),
    "train_samples": len(train_data),
    "val_samples": len(val_data),
    "num_classes": NUM_CLASSES,
    "epoch_logs": epoch_logs,
    "device": str(device),
    "gpu_name": torch.cuda.get_device_name(0) if torch.cuda.is_available() else "cpu",
}

artifact_path = os.path.join(OUTPUT_DIR, "training_run_artifact.json")
with open(artifact_path, "w") as f:
    json.dump(artifact, f, indent=2)

print(f"\n{'='*60}")
print(f"TRAINING COMPLETE")
print(f"Best macro_auroc: {best_auroc:.5f}")
print(f"Artifact saved: {artifact_path}")
print(f"{'='*60}")
print(json.dumps(artifact, indent=2))
