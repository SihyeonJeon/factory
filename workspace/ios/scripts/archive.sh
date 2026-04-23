#!/usr/bin/env bash
# Usage: scripts/archive.sh <TEAM_ID> [SCHEME=MemoryMap]
set -euo pipefail

TEAM_ID="${1:-}"
SCHEME="${2:-MemoryMap}"

if [[ -z "$TEAM_ID" ]]; then
  echo "usage: $0 <APPLE_TEAM_ID> [scheme]" >&2
  exit 1
fi

cd "$(dirname "$0")/.."
xcodegen generate
rm -rf .build/archive
xcodebuild -project MemoryMap.xcodeproj \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath .build/archive/MemoryMap.xcarchive \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  archive
xcodebuild -exportArchive \
  -archivePath .build/archive/MemoryMap.xcarchive \
  -exportPath .build/export \
  -exportOptionsPlist scripts/export-options.plist
echo "IPA: .build/export/MemoryMap.ipa"
