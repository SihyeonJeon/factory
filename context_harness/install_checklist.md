# Frontline Install Checklist

## Required

- Install full `Xcode.app` and switch with `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`.
- Sign in to `codex` with ChatGPT Pro or Plus.
- Sign in to `gemini` with personal OAuth.
- Export `ANTHROPIC_API_KEY` for Claude API use.

## Strongly recommended

- Install `xcbeautify`, `swiftlint`, `swiftformat`, `direnv`, `just`, and `fzf`.
- Install an Xcode MCP server for simulator, build, test, and docs access.
- Prefer Swift Package Manager for new iOS app dependencies.

## Verification

- `xcodebuild -version`
- `xcrun simctl list devices`
- `codex --version`
- `gemini --version`
- `python3 -c "import os; print(bool(os.environ.get('ANTHROPIC_API_KEY')))" `

## User input path

- Put detailed product intent in `context_harness/product_inputs/idea.md`
- Put hard constraints in `context_harness/product_inputs/constraints.md`
- Put design direction in `context_harness/product_inputs/design.md`
- Put release criteria in `context_harness/product_inputs/acceptance.md`
- Then run `python3 run_factory.py "Use the context_harness product inputs as the source of truth."`
