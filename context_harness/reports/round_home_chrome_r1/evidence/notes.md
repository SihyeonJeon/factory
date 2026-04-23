# round_home_chrome_r1 Evidence Notes

## Scope
- Implemented all 10 acceptance areas in `spec.md` except runtime completion, which is blocked by sandboxed Xcode/SwiftPM/CoreSimulator access.
- Preserved existing MapKit map content and bottom-sheet content; only overlay chrome, FAB positioning, selection visuals, launch arguments, and tests were changed.

## zIndex Table
| Layer | Required | Implemented |
|---|---:|---:|
| Map + markers | 10 | 10 in `MemoryMapHomeView.mapLayer` |
| MapControls | 26 | 26 |
| FilterChipBar | 28 | 28 |
| TopChrome | 30 | 30 |
| BottomSheet | 50 | 50 |
| SheetExpandedHeader | 55 | 55 in `UnfadingBottomSheet` |
| FAB | 70 | 70 in `UnfadingTabShell` |
| TabBar | 120 | 120 in `UnfadingTabShell` |

## Coordinate Formula
`sheetTopY = screenH - 83 - safeBottom - ((screenH - 83 - safeBottom) * sheetSnap.fraction)`

For the design baseline 390 x 844 with safe bottom 34 and default snap 0.50:
- available sheet height: `844 - 83 - 34 = 727`
- default sheet height: `727 * 0.50 = 363.5`
- sheet top Y: `844 - 83 - 34 - 363.5 = 363.5`

## Measurement Diff
| Element | Before | After / Expected |
|---|---|---|
| TopChrome | padding leading/trailing 14; no full 358pt banner frame; zIndex 2 | x=16, y=54, w=358, h=60; zIndex 30 |
| FilterChipBar | padding leading/trailing 14; zIndex 2 | x=0, y=108, w=390, h=44 native hit frame; zIndex 28 |
| MapControls | x≈332, y≈209.5 on 390x844 default; 44x100 stack; zIndex 3 | x=334, y=255.5 on 390x844 default; 40x88 stack; zIndex 26 |
| FAB | x=316, y≈687; fixed above tab bar only | x=316, y=289.5 on 390x844 default; follows sheet top; zIndex 70 |

## Acceptance Notes
- TopChrome: top 54, horizontal inset 16, 18pt radius, 0.5 divider, card shadow, avatar stack max 3, couple heart overlay, group subtitle copy, 32x32 search control, `onSwitchGroup` callback exposure.
- FilterChipBar: top 108, horizontal scroll, `전체` plus default `추억/밥/카페/경험` categories and dotted add button. The native accessibility frame is 44pt high rather than 32pt to preserve touch target reliability.
- MapControls: right 16, 20pt above computed sheet top, 40x40 circles, 8pt stack spacing, press scale 0.92.
- FAB: right 18, 18pt above computed sheet top, press scale 0.96, shell zIndex 70, expanded fade.
- Chrome fade: TopChrome, FilterChipBar, MapControls, and FAB use opacity 0 on expanded with 220ms easeInOut and hit testing disabled.
- Marker selected state: selected marker scales to 1.15 with halo; non-selected markers fade to opacity 0.4; selection keeps sheet at default snap per README state model.
- Launch argument: `-UI_TEST_SHEET_SNAP=<collapsed|default|expanded>` parsed in app/shell path.
- MapKit color note: README `mapBase/mapLand/mapWater/mapRoad` values are placeholder SVG map tokens; they are not applied to MapKit `.standard(elevation: .realistic)`.

## Test Additions
- Added `testHomeChromeLayoutCoordinates`.
- Added `testChromeFadesOnExpanded`.
- Adjusted `MemorySelectionStateTests` for marker select -> default snap and the default category set.
- Static test method count after change: 168 total methods, 19 UITest methods, 149 unit test methods.

## Commands
| Command | Result |
|---|---|
| `xcodegen generate` | Passed; project regenerated at `workspace/ios/MemoryMap.xcodeproj`. |
| `xcodebuild test -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath .deriveddata/r29` | Failed before build/test: CoreSimulatorService connection invalid, simulator unavailable, and new `.deriveddata/r29` attempted network SPM fetch blocked by `Could not resolve host: github.com`. |
| `xcodebuild test ... -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .deriveddata/r29 -clonedSourcePackagesDirPath .deriveddata/r28/SourcePackages -disableAutomaticPackageResolution` | Failed before build/test: CoreSimulatorService invalid and SwiftPM manifest loading attempted to write under `/Users/jeonsihyeon/.cache` / `~/Library/Caches`, which sandbox denied. |
| `HOME=$PWD/.home CLANG_MODULE_CACHE_PATH=$PWD/.cache/clang SWIFT_MODULE_CACHE_PATH=$PWD/.cache/swift xcodebuild build ...` | Failed before build: same SwiftPM cache path denial under the real home directory. |
| `xcrun swiftc -parse ...edited swift files...` | Passed; edited Swift files parse successfully. |

## Simulator Frame Verification
- Not completed in this sandboxed session because `xcodebuild` could not initialize CoreSimulatorService and SwiftPM manifest cache writes were denied before app launch.
- Expected 390x844 default-frame checks are encoded in `testHomeChromeLayoutCoordinates`; runtime verification should be rerun in an environment with simulator service and package cache access.
