# R26 Evidence Notes — Design Tokens + Fonts

## Font Bundle
- Install path: `workspace/ios/App/Fonts/`.
- App bundle resource registration: `workspace/ios/project.yml` includes `App/Fonts` as a folder resource via a `sources` entry with `buildPhase: resources`; the broader `App` source entry excludes `Fonts` to avoid flattening duplicate `.ttf` resources.
- `xcodegen generate` produced a `Fonts in Resources` folder reference in `MemoryMap.xcodeproj/project.pbxproj`, matching the `Fonts/<name>.ttf` plist paths.
- `UIAppFonts` entries are managed in `workspace/ios/project.yml` under `targets.MemoryMap.info.properties`.
- After `xcodegen generate`, `workspace/ios/App/Info.plist` contains the generated `UIAppFonts` array. The source of truth remains `project.yml`.

## PostScript Names
- `GowunDodum-Regular`
- `Nunito-Regular`
- `Nunito-SemiBold`
- `Nunito-Bold`
- `Nunito-Black`

## Grep Result
- Command: `rg '\.font\(\.system\(|Font\.system\(' workspace/ios/App workspace/ios/Features workspace/ios/Shared`
- Before implementation: 2 hits, both in `workspace/ios/Features/Composer/PlacePickerSheet.swift`.
- After implementation: 0 hits.

## Validation
- `xcodegen generate`: passed.
- `plutil -lint workspace/ios/App/Info.plist`: passed.
- YAML parse via Ruby `YAML.load_file("workspace/ios/project.yml")`: passed.
- `swiftc -parse workspace/ios/Shared/UnfadingTheme.swift`: passed.
- `swiftc -parse` on `UnfadingThemeTests.swift` and `UnfadingFontLoadingTests.swift`: passed.
- `xcodebuild test`: attempted 3 times and stopped per dispatch constraint. The sandbox blocks CoreSimulatorService (`connection became invalid`) and SwiftPM/cache writes under `/Users/jeonsihyeon`; first attempt also could not fetch packages because network is restricted. No app test binary was compiled or executed in this sandbox.

## Known Trade-Off
- Gowun Dodum is bundled as a single regular-weight face. Compatibility helpers such as `subheadlineSemibold()` map back to `GowunDodum-Regular` at the intended size, so visual weight variation is limited by design. This avoids silent system font fallback.

## Harness Note
- `context_harness/operator/locks/round_design_tokens_r1.lock` was not present during the coding session. The supplied `spec.md` and user dispatch were treated as the active scope.
