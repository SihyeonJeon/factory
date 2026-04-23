# Phase 2 Release Notes — 2026-04-24

Audience: internal device verification / TestFlight pre-upload review
Build line: R26-R39 integrated

## What Changed

### Map / Home
- Custom 3-tab shell replaced the earlier stock tab layout.
- Home FAB now opens the rebuilt composer from the map surface.
- Top chrome, filter chips, and map controls were repositioned and fade correctly with sheet transitions.
- Group picker and category editor overlays now open from the new chrome affordances.

### Composer
- Composer was rebuilt around the latest prototype flow.
- Place confirmation is now explicit before save.
- Event binding, travel toggle, participant selection, emotion tags, and optional cost entry were added.
- Photo metadata seeding still helps infer place and time, but save gating is clearer for users.

### Memory Detail
- Memory detail now follows the Sprint 28 structure.
- Same-event prev/next navigation, KST meta strip, similar-place cards, event mini gallery, participant row, and inline "한 줄 더 쓰기" are all visible on device.

### Calendar / Plans
- Calendar month label now opens a month picker.
- Day detail includes weather placeholder, event cards, and a general-group meeting plan card.
- Local RSVP summary and the "알림 보내기" toast flow are present for device smoke.

### Rewind
- Rewind moved to a stories-style full-screen experience.
- Cards now cover cover/TOP3/first visit/photo-heavy day/emotion cloud/time together.
- Home curation entry opens directly into the new rewind flow.

### Settings / Group Hub
- Settings now links into the expanded Group Hub.
- Group overview, member state, role labels, invite placeholders, appearance placeholders, notification toggles, and data/export placeholders are integrated.

### Launch Prep
- Archive script and App Store export plist are prepared.
- Screenshot harvest helper exists for UITest attachment extraction.
- Signed archive and upload remain deferred until Apple signing prerequisites exist.

## Real-Device Checks

1. Open map, calendar, rewind, and settings tabs and verify the custom shell stays stable.
2. Open composer from FAB and confirm save remains disabled until place confirmation.
3. Open a memory detail card and verify Sprint 28 section ordering and same-event navigation.
4. Open calendar month picker, general-group plan card, and the local notification toast path.
5. Open Rewind stories and tap through multiple cards.
6. Open Group Hub from Settings and verify member labels, invite placeholders, and toggles.

## Known Deferred

- Apple Sign in
- Edge Function receipt validation
- HIBP leaked-password protection toggle
- Real TestFlight archive/export/upload
