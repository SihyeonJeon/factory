#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[setup] Homebrew formulas for frontier iOS/agent harness"
brew install jq fd fzf just direnv xcbeautify swiftformat swiftlint xcodes || true

echo "[setup] Ruby/iOS helpers"
brew install fastlane cocoapods || true

echo "[setup] Python venv dependencies"
"$ROOT_DIR/venv/bin/pip" install --upgrade pip || true

echo "[setup] Repo-local directories"
mkdir -p \
  "$ROOT_DIR/reports" \
  "$ROOT_DIR/context_harness/handoffs" \
  "$ROOT_DIR/.worktrees"

echo "[setup] Apply home harness templates"
"$ROOT_DIR/venv/bin/python" "$ROOT_DIR/scripts/apply_home_harness.py"

echo "[setup] Done"
