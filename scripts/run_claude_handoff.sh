#!/bin/zsh
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <handoff.json> [model]" >&2
  echo "  models: opus (heavy) | sonnet (default) | haiku (light)" >&2
  exit 1
fi

handoff_file="$1"
model="${2:-sonnet}"

if [[ ! -f "$handoff_file" ]]; then
  echo "missing handoff file: $handoff_file" >&2
  exit 1
fi

prompt=$'You are the BirdCLEF 2026 strategy and critique lane.\nConsume the following handoff JSON as the entire task contract.\nReturn only the requested deliverable content, grounded in the contract.\n\n'
prompt+="$(cat "$handoff_file")"

claude -p --model "$model" --permission-mode default "$prompt"
