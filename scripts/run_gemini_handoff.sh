#!/bin/zsh
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <handoff.json> [model]" >&2
  echo "  models: gemini-2.5-pro (heavy) | gemini-2.5-flash (default)" >&2
  exit 1
fi

handoff_file="$1"
model="${2:-gemini-2.5-flash}"

if [[ ! -f "$handoff_file" ]]; then
  echo "missing handoff file: $handoff_file" >&2
  exit 1
fi

prompt=$'You are the BirdCLEF 2026 external-evidence lane.\nConsume the following handoff JSON as the full task contract.\nUse current external evidence and return only the requested deliverable content.\n\n'
prompt+="$(cat "$handoff_file")"

gemini -p "$prompt" -m "$model"
