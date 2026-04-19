# Remediation Round 5 — Sprint 3 Visual QA Findings

**Date:** 2026-04-13
**Source:** visual_qa_visual_qa.md (CONDITIONAL PASS)
**Goal:** Fix 1 blocker + 1 advisory. All 56 tests must remain green.

---

## Fix 1: Camera Permission (BLOCKER — TestFlight/App Store)

### Problem
`NSCameraUsageDescription` is missing from Info.plist, and there is no `AVCaptureDevice.requestAccess(for: .video)` call before presenting the camera.

### Implementation

1. **`workspace/ios/Resources/Info.plist`** (or project.yml plist settings)
   - Add `NSCameraUsageDescription` key with value: `"사진을 촬영하여 추억에 추가합니다"` (Korean localized camera usage description)

2. **`workspace/ios/project.yml`** modification
   - Under `settings > base > info`, add:
     ```yaml
     NSCameraUsageDescription: "사진을 촬영하여 추억에 추가합니다"
     ```

3. **`Features/Home/CameraCaptureView.swift`** modification
   - Before presenting `UIImagePickerController`, check camera authorization:
     ```swift
     let status = AVCaptureDevice.authorizationStatus(for: .video)
     switch status {
     case .notDetermined:
         AVCaptureDevice.requestAccess(for: .video) { granted in
             if granted { /* present camera */ }
         }
     case .authorized:
         // present camera
     case .denied, .restricted:
         // show alert directing user to Settings
     @unknown default:
         break
     }
     ```
   - Add `import AVFoundation` if not present

---

## Fix 2: FAB Accessibility Hint (Advisory)

### Problem
The floating action button in `MemoryMapHomeView.swift` is missing `.accessibilityHint`.

### Implementation

1. **`Features/Home/MemoryMapHomeView.swift`** modification
   - Find the FAB button (around line 607) and add:
     ```swift
     .accessibilityHint("새로운 추억을 기록합니다")
     ```

---

## Constraints

- Run `xcodegen generate && xcodebuild -project MemoryMap.xcodeproj -scheme MemoryMap -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/memorymap_build test` after all edits.
- All 56 existing tests must pass.
