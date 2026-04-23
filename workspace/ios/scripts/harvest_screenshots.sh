#!/usr/bin/env bash
# Usage: scripts/harvest_screenshots.sh <Test.xcresult> [output_dir=AppStoreScreenshots]
set -euo pipefail

RESULT_BUNDLE="${1:-}"
OUTPUT_DIR="${2:-AppStoreScreenshots}"

if [[ -z "$RESULT_BUNDLE" ]]; then
  echo "usage: $0 <Test.xcresult> [output_dir]" >&2
  exit 1
fi

cd "$(dirname "$0")/.."
mkdir -p "$OUTPUT_DIR"

tests_json="$(mktemp)"
activities_json="$(mktemp)"
test_ids_file="$(mktemp)"
trap 'rm -f "$tests_json" "$activities_json" "$test_ids_file"' EXIT

xcrun xcresulttool get test-results tests --path "$RESULT_BUNDLE" --format json > "$tests_json"
/usr/bin/python3 - "$tests_json" > "$test_ids_file" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    data = json.load(handle)

def walk(value):
    if isinstance(value, dict):
        test_id = value.get("testIdentifier") or value.get("identifier")
        name = value.get("name", "")
        if test_id and "UnfadingUITests" in str(name):
            print(test_id)
        for child in value.values():
            walk(child)
    elif isinstance(value, list):
        for child in value:
            walk(child)

walk(data)
PY

index=1
while IFS= read -r test_id; do
  xcrun xcresulttool get test-results activities --test-id "$test_id" --path "$RESULT_BUNDLE" --format json > "$activities_json"
  /usr/bin/python3 - "$activities_json" <<'PY' | while IFS=$'\t' read -r name payload_id; do
import json
import re
import sys

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    data = json.load(handle)

def sanitize(value):
    value = re.sub(r"[^A-Za-z0-9._-]+", "_", value.strip())
    return value or "screenshot"

def walk(value):
    if isinstance(value, dict):
        payload_id = value.get("payloadId") or value.get("payloadRef", {}).get("id")
        name = value.get("name") or value.get("filename") or "screenshot"
        uniform_type = value.get("uniformTypeIdentifier") or value.get("uti") or ""
        if payload_id and ("png" in str(uniform_type).lower() or str(name).lower().endswith(".png")):
            print(f"{sanitize(str(name).removesuffix('.png'))}\t{payload_id}")
        for child in value.values():
            walk(child)
    elif isinstance(value, list):
        for child in value:
            walk(child)

walk(data)
PY
    output="$OUTPUT_DIR/$(printf "%02d" "$index")_${name}.png"
    xcrun xcresulttool export object --legacy --path "$RESULT_BUNDLE" --output-path "$output" --id "$payload_id" --type file
    index=$((index + 1))
  done
done < "$test_ids_file"

echo "Screenshots: $OUTPUT_DIR"
