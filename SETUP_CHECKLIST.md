# Setup Checklist

## Must complete first

- Install full `Xcode.app`
- Run `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
- Open Xcode once and accept license
- Sign into the App Store / Apple Developer account if device or archive workflows are needed

## Harness environment

- Export `ANTHROPIC_API_KEY`
- Verify `codex login` is using your ChatGPT Pro account
- Verify `gemini` is signed in with personal OAuth
- Run `./scripts/setup_frontier_harness.sh`

## Validation

- `xcodebuild -version`
- `xcrun simctl list devices`
- `codex --version`
- `gemini --version`
- `python orchestrator.py team-report`

## Recommended next installs

- `xcodes` for Xcode version management
- `xcbeautify` for readable build logs
- `swiftformat` and `swiftlint` for consistency
- `direnv` and `just` for reproducible local commands

## Workflow

- `python orchestrator.py intake "<brief>"`
- `python orchestrator.py delivery "<brief>"`
- `python orchestrator.py evaluation "<brief>" --image-path <screenshot>`
