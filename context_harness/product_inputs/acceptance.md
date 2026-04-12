# Acceptance Criteria

## MVP scope

### Epic 1: Group creation and invitations

- Create a group with required name, mode selection (`couple` or `general_group`), and optional image and intro.
- Invite members by code or link.
- Allow one user to join multiple groups.

### Epic 2: Event containers, place pins, and memory records

- Create or select an event container for a date, meetup, or trip span.
- Allow inline event creation when the user uploads the first memory and no current event exists for that time.
- Default new events to a single day and allow explicit promotion to a multi-day trip.
- Create pins from first-photo metadata, search, direct map interaction, or current-location quick action.
- Attach time from first-photo metadata when available, with an option to replace with current time.
- Attach multiple photos, short note, and emotion tags to a memory.
- Support multiple user posts under a single memory.
- Suggest merging when the same place is revisited.
- Allow reactions to other members' memory records.

### Epic 3: Shared memory map

- Show group memory pins on a map with clustering.
- Support time filtering.
- Show filtered event and memory history when opening a marker or cluster.
- Keep marker selection and bottom-sheet content synchronized.
- Use adaptive curation in the default bottom sheet based on available memory density and relevance rather than a fixed mandatory section order.

### Epic 4: Rewind reminders

- Support "N years ago today" reminders.
- Support optional location-based reminders.
- Show a shareable rewind card with photo, place, people, and emotion context.

## Release blockers

- Any unresolved HIG violation.
- Any screen that breaks safe-area handling or conflicts with iPhone gestures.
- Any primary interactive element smaller than 44 x 44 pt.
- Any unreadable text contrast or dark-mode failure in core flows.
- Any unfinished spacing, placeholder-heavy layout, fake CTA, or obvious AI-draft visual state.
- Missing QA evidence, screenshot evidence, or accessibility-sensitive review notes.
- Missing native iOS evidence once the native project exists.
- Any bottom-sheet interaction that feels janky, desynchronized from map state, or non-native.

## Evaluation evidence

- Code review with concrete file-level findings.
- Screenshot-level visual QA with explicit pass/fail reasoning.
- HIG audit tied to visible behavior, not generic taste.
- Interaction evidence for marker-to-sheet synchronization, cluster filtering, and memory-detail navigation.
- Native Xcode evidence once native project exists:
  - `xcodebuild -list`
  - successful simulator build
  - simulator or preview evidence when available
- Expo-web evidence may still be used as supporting smoke-test evidence, but it cannot outrank native evidence after native artifacts exist.

## Nice to have

- Group timeline and yearly recap statistics.
- Auto-generated year-end memory reports.
- Diary cover customization, richer map themes, and premium icon packs.
- Premium customization and advanced rewind behavior under subscription.

## Detailed acceptance rules

- Group creation requires a name; image and intro are optional.
- Group creation requires explicit mode selection between `couple` and `general_group`.
- Invite links expire after 24 hours and can be reissued.
- One user may belong to up to 20 groups.
- Group owners can remove members and delete the group.
- Event containers support a single day by default and may optionally span multiple days.
- Multi-day behavior should require explicit user intent rather than being inferred automatically.
- If no active event exists for the selected time, the upload flow must support creating a new event inline.
- A visit record can contain up to 10 photos.
- Photo input sources must include photo library, document picker, and in-app capture.
- In-app capture should attach capture time metadata and attach location metadata whenever location permission is granted.
- The first uploaded photo's metadata should prefill place and time when available.
- The representative coordinate should remain stable unless the user explicitly changes the place.
- The place field shown to the user should default to a readable address or place label, not raw coordinates.
- Users must be able to confirm or override the auto-filled place through at least one friendly method such as search or manual place naming.
- Saving must require explicit confirmation of the final place value.
- If the suggested place is incorrect, users must be able to switch to direct place selection or set the device's current location before saving.
- Cost entry must remain optional in all modes.
- Emotion tags come from a predefined set of 6 and allow multi-select.
- Revisiting a place suggests merging into existing history.
- Initial map load auto-fits visible pins.
- Cluster taps zoom into the selected area.
- Cluster taps must also filter bottom-sheet content to the memories represented by that cluster.
- Time filters animate pin appearance and disappearance.
- Marker selection should automatically raise the bottom sheet to its default browsing height.
- The default bottom sheet shows curated groupings when no marker is selected.
- The selected marker or cluster state must replace the default curation with filtered event and memory content.
- The newest visit appears first in the selected context detail.
- Memory cards in the bottom sheet must open a dedicated memory detail page.
- The memory detail page should support moving to other nearby or related memories when this improves browsing continuity.
- The bottom-sheet memory list must visibly group content under a parent date or meetup.
- Date-based rewind defaults to 10 AM and must be user-configurable.
- Location-based reminders must be individually switchable.
- Default location reminder radius is 200 m, adjustable from 100 m to 500 m.
- Rewind cards must support external sharing.

## Main-screen interaction contract

- The main screen must contain four visual layers:
  - full-screen map
  - floating top header
  - floating add-memory action
  - foreground animated bottom sheet
- The bottom sheet must support three snap states:
  - collapsed summary
  - default browsing
  - expanded detail browsing
- Default collapsed content should present curated memory groupings or recommendations.
- Default curation should be algorithmically adaptive to the actual memory set rather than hard-coded to one static sequence.
- Selected marker content and selected cluster content must be distinguishable in the sheet header and content list.
- The bottom sheet should feel close to iPhone Photos event-grouped browsing, not a generic modal drawer.
