#!/usr/bin/env bash
set -euo pipefail

scheme_path="MemoryMap.xcodeproj/xcshareddata/xcschemes/MemoryMap.xcscheme"

if [[ ! -f "$scheme_path" ]]; then
  echo "Missing scheme: $scheme_path" >&2
  exit 1
fi

if awk '/<TestAction/,/<\/TestAction>/' "$scheme_path" | grep -q "StoreKitConfiguration.storekit"; then
  exit 0
fi

tmp="$(mktemp)"
awk '
  /<\/TestAction>/ {
    print "      <StoreKitConfigurationFileReference"
    print "         identifier = \"../../StoreKitConfiguration.storekit\">"
    print "      </StoreKitConfigurationFileReference>"
  }
  { print }
' "$scheme_path" > "$tmp"
mv "$tmp" "$scheme_path"
