# Sprint History

## Sprint Timeline

| Sprint | Date | Scope | Tests | Result |
|--------|------|-------|-------|--------|
| 1-7 | 2026-04-08 ~ 04-11 | Core app: map, memories, groups, rewind | 75 | GREEN |
| 8-A | 2026-04-14 | Unfading rebrand, Korean, search | 75 | GREEN |
| 8-B | 2026-04-14 | Warm couple design (UnfadingTheme) | 75 | SHIP-CLEAR |
| 9 | 2026-04-14 | Bottom sheet snap, clustering, gallery | 79 | SHIP-CLEAR |
| 10 | 2026-04-14 | Supabase schema + iOS integration | 79 | GREEN |
| 11 | 2026-04-14 | Sheet layout, FAB, search compact, dummy data | 79 | PASS (advisory only) |
| 12 | 2026-04-14 | Tab redesign, calendar, settings, motion | 79 | GREEN |
| 13 | 2026-04-14 | Photo display (PHAsset), cluster photos | 79 | GREEN |
| 14 | 2026-04-14 | Location permission, MKLocalSearch | 79 | BLOCKED → remediated |
| Rem-14 | 2026-04-14 | Fix B-1 (launch permission), B-2 (a11y) | 79 | GREEN |
| Rem-14b | 2026-04-14 | Fix showsUserLocation on map load | 79 | GREEN |
| Rem-14c | 2026-04-14 | Lazy CLLocationManager init (iOS 26) | 79 | GREEN (erased sim verified) |
| Sprint 15 | 2026-04-14 | Visual polish + advisory fixes | 79 | GREEN |
| Sprint 16 | 2026-04-14 | Photos permission guard | — | Already fixed (verified) |
| Sprint 17 | 2026-04-14 | Code drift fix (semantic font + a11y) | 79 | PASS |
| Sprint 18 | 2026-04-14 | PlaceSearchService → ManualPlacePickerSheet | 79 | PASS |
| Sprint 19 | 2026-04-14 | Final eval + coding conventions audit | 79 | PASS, 0 violations |
| Sprint 20 | 2026-04-14 | HF3: animation fix, search bar, map controls, location permission | 77 | PASS |
| Sprint 21 | 2026-04-14 | HF3: sheet full-screen, 메인/보관함 tabs | 77 | PASS |
| Sprint 22 | 2026-04-14 | HF3: calendar dial picker, time wheel | 77 | PASS |
| Sprint 23 | 2026-04-14 | HF3: marker→sheet, back button, cluster filter | 77 | PASS |
| Sprint 24 | 2026-04-14 | HF3 remediation: coordinator, textOnPrimary, 44pt, race | 77 | PASS |
| Sprint 25 | 2026-04-14 | Drift fix: .white → textOnPrimary/textOnOverlay (20건) | 77 | PASS |
| Sprint 26 | 2026-04-14 | HF4: sheet clip/fullscreen, year comma, back chevron | 77 | PASS |
| Sprint 27 | 2026-04-14 | HF4: archive event grouping (sectioned LazyVStack) | 77 | PASS |
| Sprint 28 | 2026-04-14 | HF4: detail redesign (prev/next fix, weather, nav bar) | 77 | PASS |
| Sprint 29 | 2026-04-14 | HF4: calendar planning + group swap | 77 | PASS |
| Sprint 30 | 2026-04-14 | HF4 remediation: CalendarView group filter + reaction label | 77 | PASS |

## Blockers Encountered

| Sprint | Blocker | Root Cause | Fix |
|--------|---------|-----------|-----|
| 8-A | Old MemoryMap scheme | probes.py hardcoded name | Dynamic xcodeproj.stem |
| 8-B | White-on-coral contrast | Primary too light (0.96) | Deepened to 0.85 |
| 14 | Location on launch | handleCurrentLocationTap in .task | Removed, gesture-only |
| 14 | Zero a11y on map pins | No accessibilityLabel | Added to MemoryClusterMapView |
| 14 | showsUserLocation on map | MKMapView auto-requests location | Guard behind .authorized |
| 14 | CLLocationManager() init triggers dialog | iOS 26 behavior | Lazy init, create on first gesture |
