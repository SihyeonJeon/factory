# round_composer_redesign_r1 spec

## Scope
Full redesign of `MemoryComposerSheet.swift` per deepsight prototype. Use new reusable module `UnfadingPhotoGrid` + state object `MemoryComposerState`.

## Base commit
`db47bb3`

## Deliverables

### New reusable module
- `workspace/ios/Shared/UnfadingPhotoGrid.swift` — reusable 4-col photo grid with add affordance and PhotosUI `PhotosPicker` binding. API:
  ```swift
  struct UnfadingPhotoGrid: View {
      init(selection: Binding<[PhotosPickerItem]>, maxSelection: Int = 12)
  }
  ```

### New state
- `workspace/ios/Features/Home/MemoryComposerState.swift` — `@MainActor ObservableObject` managing note text, selected photos, selected place, time, mood tags, save-enabled state.

### Rewrite
- `workspace/ios/Features/Home/MemoryComposerSheet.swift` — sections in order: 사진 / 장소 / 시간 / 메모 / 감정. Inferred place + time confirm/edit row. Primary save CTA with `.unfadingPrimary`.

### Localization additions
- `UnfadingLocalized.Composer` — add: `photoSection` / `timeLabel` / `noteLabel` / `placeConfirmPrompt` / `timeInferredPrompt` / `saveDraft` / `savePrimary` / `placeEditAction` / `timeEditAction` / `moodLabel`.

### Tests
- `UnfadingPhotoGridTests` — view builds for empty + populated selection; grid column count assertion
- `MemoryComposerStateTests` — state transitions (add/remove photo, set note, toggle mood, saveEnabled gating)

## Vibe-coding-limits 2026 items cited (v5.7 §13)
Dispatch must guard against:
- Silent `try?` error suppression → use `do-catch` with user-facing error surface
- Missing `@MainActor` on view-model-scoped class
- `[weak self]` missing in PhotosPicker async data load closures
- English literal regression in new code
- Hardcoded font sizes (Dynamic Type violation)
- Hit target < 44pt

## Acceptance
- Build ✅
- Tests ≥ 57 (51 + 6 new)
- Composer Korean full
- Runtime screenshot of composer open state captured
- Codex peer review recorded; blockers fixed via additional Codex dispatch (NOT operator edits)
