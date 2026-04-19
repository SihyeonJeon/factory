# Sprint 19 — Final Evaluation & Regression Check

**Date:** 2026-04-14
**Source:** Round 3 plan — final verification sprint
**Goal:** Full regression test + accessibility audit + coding conventions compliance

---

## Scope

This is a **verification-only** sprint. No new features. Run the full test suite and audit code for compliance with coding-conventions.md.

---

## Gate 1: Test Suite

```bash
cd workspace/ios && xcodegen generate && xcodebuild -project Unfading.xcodeproj -scheme Unfading -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/unfading_build test
```

**Pass criteria:** ≥79 tests, 0 failures.

---

## Gate 2: Coding Conventions Audit

Check ALL Swift files in `Features/` and `Shared/` for:

### 2a. Forbidden patterns (must find ZERO)
- `.font(.system(size:` — hardcoded font (exception: `@ScaledMetric`)
- `Color(red:` or `Color.red` / `.blue` etc — inline color (exception: `.white`, `.black`, `.clear`)
- `CLLocationManager()` outside of LocationPermissionStore lazy init
- `PHAsset.fetchAssets` without authorization check
- English UI text in `Text()` or `.accessibilityLabel()`

### 2b. Required patterns (must find on ALL interactive elements)
- `.accessibilityLabel()` on all Buttons, NavigationLinks, Toggles
- `.frame(minHeight: 44)` or equivalent on all interactive elements
- `UnfadingTheme.` for all colors

### Report format

```
AUDIT RESULTS:
- Hardcoded fonts: [count] violations → [file:line list]
- Inline colors: [count] violations → [file:line list]
- Missing accessibility: [count] violations → [file:line list]
- Permission violations: [count] → [file:line list]
- English UI text: [count] → [file:line list]
- Touch target violations: [count] → [file:line list]

VERDICT: PASS / FAIL
```

If FAIL: fix violations in-place, re-run tests, re-audit.

---

## Files to audit (read-only unless fixing violations)

| Directory | Scope |
|---|---|
| `Features/Home/*.swift` | All home views |
| `Features/Calendar/*.swift` | Calendar views |
| `Features/Settings/*.swift` | Settings views |
| `Features/Rewind/*.swift` | Year-end report |
| `Shared/*.swift` | All shared modules |
| `App/*.swift` | App entry |

---

## Constraints

- Fix any violations found — modify only the minimum needed
- Re-run full test suite after any fix
- All tests must pass (≥79)
- Report final test count and audit results
