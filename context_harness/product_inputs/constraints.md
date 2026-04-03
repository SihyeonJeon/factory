# Constraints

## Platform

- Primary target: native iOS app built with SwiftUI.
- Transitional support: Expo web may be used only as a temporary prototype and smoke-test harness.
- Once the native project exists, native Xcode evidence outranks Expo-only evidence.

## Must-have MVP features

- Group creation with image, intro, and invitation flow.
- Place pin creation from search or direct map selection.
- Memory records with date, photos, short note, and emotion tags.
- Shared memory map with clustering and time filtering.
- Rewind reminders based on date and optionally location.
- Social interaction inside a memory record, including reactions.

## Product constraints

- The product must be clearly group-oriented, not couple-only.
- The map must be the primary memory surface, not a secondary utility.
- Memory retrieval should be tied to place, time, and group context.
- Users should be able to see both repeated visits and layered history at the same place.

## App Store and HIG constraints

- Every interactive element must meet the 44 x 44 pt touch target rule.
- Safe areas and Dynamic Island clearance are non-negotiable.
- Text contrast, dark mode, Dynamic Type, and accessibility labels must be supported in core flows.
- The result must feel like a premium iOS app, not like a rushed AI-generated layout.
- Any unresolved HIG failure blocks release.

## Technical constraints

- Favor SwiftUI-first native architecture.
- Treat maps, location permissions, notifications, and photo access as first-class native capabilities.
- Avoid web-first abstractions that distort the native iOS experience.
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
- Premium can unlock more groups, richer rewind behavior, more storage, and visual customization.
- Monetization patterns must avoid deceptive or review-risky behavior.
