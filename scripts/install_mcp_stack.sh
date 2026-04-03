#!/bin/bash
set -euo pipefail

echo "Install XcodeBuildMCP into Claude Code:"
echo "CI=1 npx -y @smithery/cli@latest mcp add cameroncooke/xcodebuildmcp --client claude-code"
echo ""
echo "Install XcodeBuildMCP into Codex:"
echo "CI=1 npx -y @smithery/cli@latest mcp add cameroncooke/xcodebuildmcp --client codex"
echo ""
echo "Install AXe after Command Line Tools are updated:"
echo "brew install cameroncooke/axe/axe"
echo ""
echo "Project-scoped fallback config lives in .mcp.json"
