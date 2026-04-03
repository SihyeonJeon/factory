#!/bin/bash
# setup_env.sh - Company harness environment bootstrap
set -euo pipefail

echo "=== Factory Harness Setup ==="

if [ ! -d "venv" ]; then
  echo "> Creating Python virtualenv..."
  python3 -m venv venv
fi

source venv/bin/activate

echo "> Upgrading Python tooling..."
pip install --upgrade pip
pip install playwright requests claude-agent-sdk

echo "> Installing Playwright Chromium..."
playwright install chromium

echo ""
echo "=== CLI Status ==="
echo -n "Codex CLI:   "; codex --version 2>/dev/null || echo "NOT FOUND"
echo -n "Gemini CLI:  "; gemini --version 2>/dev/null || echo "NOT FOUND"
echo -n "Claude CLI:  "; claude --version 2>/dev/null || echo "OPTIONAL - not required for new harness"

echo ""
echo "=== Environment Checks ==="
python3 - <<'PY'
import os
print("ANTHROPIC_API_KEY:", "SET" if os.environ.get("ANTHROPIC_API_KEY") else "MISSING")
PY

echo ""
echo "=== Manual iOS Prerequisites ==="
echo "- Install full Xcode.app from the App Store."
echo "- Run: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
echo "- Verify: xcodebuild -version"
echo "- Verify: xcrun simctl list devices"

echo ""
echo "=== Recommended Tooling ==="
echo "- Run scripts/install_frontline_tools.sh after approving brew installs."
echo "- Review context_harness/install_checklist.md"

echo ""
echo "=== Setup Complete ==="
echo "source venv/bin/activate && python run_factory.py [seed]"
echo "or run: ./venv/bin/python run_factory.py [seed]"
