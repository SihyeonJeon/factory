#!/bin/zsh
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "usage: $0 <submission.csv> <notebook-slug> <version> [message]" >&2
  exit 1
fi

submission_csv="$1"
notebook_slug="$2"
version="$3"
message="${4:-BirdCLEF 2026 submission}"

if [[ ! -f "$submission_csv" ]]; then
  echo "missing submission file: $submission_csv" >&2
  exit 1
fi

if [[ -z "${KAGGLE_USERNAME:-}" || -z "${KAGGLE_TOKEN:-}" ]]; then
  echo "KAGGLE_USERNAME and KAGGLE_TOKEN must be set in the environment" >&2
  exit 1
fi

kaggle competitions submit \
  -c birdclef-2026 \
  -f "$submission_csv" \
  -k "sihyeona/$notebook_slug" \
  -v "$version" \
  -m "$message"
