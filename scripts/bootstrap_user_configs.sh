#!/bin/bash
set -euo pipefail

CLAUDE_SETTINGS="$HOME/.claude/settings.json"
GEMINI_SETTINGS="$HOME/.gemini/settings.json"
ZSHRC="$HOME/.zshrc"

echo "This script prints the target user-level settings to apply."
echo "Edit and merge carefully if your local files already contain custom entries."
echo ""
echo "--- ~/.claude/settings.json target ---"
cat <<'JSON'
{
  "model": "opus",
  "enabledPlugins": {
    "codex@openai-codex": true
  }
}
JSON

echo ""
echo "--- ~/.gemini/settings.json target additions ---"
cat <<'JSON'
{
  "security": {
    "auth": {
      "selectedType": "oauth-personal"
    }
  }
}
JSON

echo ""
echo "--- ~/.zshrc target additions ---"
cat <<'SH'
export ANTHROPIC_API_KEY=...
export PATH="$HOME/.local/bin:$PATH"
eval "$(direnv hook zsh)"
SH

echo ""
echo "Paths:"
echo "$CLAUDE_SETTINGS"
echo "$GEMINI_SETTINGS"
echo "$ZSHRC"
