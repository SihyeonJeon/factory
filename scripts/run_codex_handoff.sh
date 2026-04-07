#!/bin/zsh
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <handoff.json> [model]" >&2
  echo "  models: o3 (heavy) | o4-mini (default)" >&2
  exit 1
fi

handoff_file="$1"
model="${2:-o3}"

if [[ ! -f "$handoff_file" ]]; then
  echo "missing handoff file: $handoff_file" >&2
  exit 1
fi

prompt=$'You are the BirdCLEF 2026 implementation lane.\nConsume the following handoff JSON as the full task contract.\nMake only the changes necessary to satisfy the contract and report concrete outputs.\n\n'
prompt+="$(cat "$handoff_file")"

codex exec --model "$model" --sandbox workspace-write --cd . "$prompt"
