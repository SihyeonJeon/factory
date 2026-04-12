# Constraints

## Platform

- Primary target: native iOS app built with SwiftUI.
- Transitional support: Expo web may be used only as a temporary prototype and smoke-test harness.
- Once the native project exists, native Xcode evidence outranks Expo-only evidence.

## Must-have MVP features

- Group creation with mode selection, image, intro, and invitation flow.
- Place pin creation from search, first-photo metadata, direct map selection, or current-location quick action.
- Date or meetup creation with date/time metadata, optional multi-day span, and event-level summary fields.
- Memory records with photos, short note, and emotion tags under an event.
- Shared memory map with clustering, cluster filtering, and time filtering.
- Rewind reminders based on date and optionally location.
- Social interaction inside a memory record, including reactions and multiple user posts under one memory.

## Product constraints

- The product must support both couple mode and general group mode from the creation flow onward.
- Couple mode must not require a separate app or separate domain model.
- The product must remain valid for recurring groups and not collapse into a couple-only product.
- The map must be the primary memory surface, not a secondary utility.
- Memory retrieval should be tied to place, time, event, and group context.
- Users should be able to see both repeated visits and layered history at the same place.
- The bottom sheet must behave as a first-class exploratory surface, not as a temporary modal.
- Marker and bottom-sheet states must stay synchronized.

## App Store and HIG constraints

- Every interactive element must meet the 44 x 44 pt touch target rule.
- Safe areas and Dynamic Island clearance are non-negotiable.
- Text contrast, dark mode, Dynamic Type, and accessibility labels must be supported in core flows.
- The result must feel like a premium iOS app, not like a rushed AI-generated layout.
- Any unresolved HIG failure blocks release.

## Technical constraints

- Favor SwiftUI-first native architecture.
- Treat maps, location permissions, notifications, photo access, camera capture, and metadata extraction as first-class native capabilities.
- Avoid web-first abstractions that distort the native iOS experience.
- The data model must support:
  - `Group`
  - `DateEvent` or equivalent event container
  - `Memory`
  - `MemoryPost`
- The canonical hierarchy is:
  - `Group` -> `DateEvent` -> `Memory` -> `MemoryPost`
- `DateEvent` should default to a single-day event and support explicit promotion to a multi-day trip event.
- When a user creates the first memory and there is no active event covering the selected timestamp, the app must allow event creation inline.
- Multiple users must be able to attach their own text and photos to the same `Memory` through separate `MemoryPost` entries.
- The first uploaded photo should be the default source for time and place metadata when present.
- The representative coordinate for a memory should remain stable unless the user explicitly edits it.
- Photo-derived coordinates should auto-fill the place field during memory creation, but the UI should expose a human-readable place name or address rather than raw latitude/longitude by default.
- The app must require user confirmation of auto-filled place information before final save.
- A single action must allow replacing derived metadata with the device's current location and current time.
- Photo input sources must include:
  - gallery / photo library
  - files / document picker
  - capture now / in-app camera
- In-app camera capture should preserve or attach at least capture time and location metadata whenever permissions allow.
- Place entry should support at least one user-friendly override path such as searchable place lookup or manual place-name entry.
- If the inferred place is wrong, the user must be able to choose a place directly or replace it with the device's current location before saving.
- The implementation may use external place and geocoding services when needed to convert coordinates into recognizable place labels and support place search.
- Cost entry is always optional regardless of mode.
- Use physical separation for context:
  - `workspace/` for code
  - `context_harness/` for policy and handoffs
  - `reports/` for long evaluation output
  - `.worktrees/` for isolated implementation lanes

## Token and orchestration constraints

- No single provider may both implement and self-approve release-critical work.
- Use compressed handoff artifacts instead of replaying full history.
- Compression targets:
  - Product handoff: <= 800 words
  - Delivery plan: <= 700 words
  - Builder brief: <= 400 words
  - Review summary: <= 500 words
- If the same context is used repeatedly, promote it into a stable file instead of pasting it again.
- Engineering should only re-enter after evaluation produces concrete, localized feedback.

## Hardware and automation constraints

- The long-term autonomous target is a dedicated Mac-based agent box for heavy native builds and unattended operation.
- Blocking interactive prompts should be avoided or isolated from the main automation loop.
- Native iOS build reliability matters more than web-only convenience.

## Monetization constraints

- Use a freemium plus subscription model.
- Free tier should be enough to prove value but clearly limited.
- Premium can unlock more groups, richer rewind behavior, more storage, visual customization, and advanced calendar/cost analytics.
- Monetization patterns must avoid deceptive or review-risky behavior.

## Interaction constraints

- Main-screen map exploration should follow a marker-driven bottom-sheet pattern similar to strong native map apps.
- Cluster taps must filter the bottom sheet to the memories inside that cluster.
- Marker taps must filter the bottom sheet to the selected place or event context and raise the sheet to a useful browsing height.
- Tapping a memory card inside the sheet must navigate to a dedicated memory detail page.
- The bottom-sheet list should group photos and memories under their parent date or meetup similarly to event grouping in the iPhone Photos app.
- The bottom sheet should be treated as the primary gallery surface, while the detail page should support efficient movement between nearby or related memories when appropriate.
