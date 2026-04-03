#!/bin/bash
set -euo pipefail

echo "Installing recommended frontline tools with Homebrew..."
brew install xcbeautify swiftlint swiftformat direnv just fzf

echo ""
echo "Current Xcode selection:"
xcode-select -p || true

echo ""
echo "Manual follow-up:"
echo "- Install Xcode.app from the App Store if it is missing."
echo "- Then run: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"

