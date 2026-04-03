# Acceptance Criteria

## MVP scope

### Epic 1: Group creation and invitations

- Create a group with required name and optional image and intro.
- Invite members by code or link.
- Allow one user to join multiple groups.

### Epic 2: Place pins and memory records

- Create pins from search or direct map interaction.
- Attach date, multiple photos, short note, and emotion tags to a visit.
- Suggest merging when the same place is revisited.
- Allow reactions to other members' memory records.

### Epic 3: Shared memory map

- Show group memory pins on a map with clustering.
- Support time filtering.
- Show reverse-chronological place history when opening a pin.

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

## Evaluation evidence

- Code review with concrete file-level findings.
- Screenshot-level visual QA with explicit pass/fail reasoning.
- HIG audit tied to visible behavior, not generic taste.
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
- Invite links expire after 24 hours and can be reissued.
- One user may belong to up to 20 groups.
- Group owners can remove members and delete the group.
- A visit record can contain up to 10 photos.
- Emotion tags come from a predefined set of 6 and allow multi-select.
- Revisiting a place suggests merging into existing history.
- Initial map load auto-fits visible pins.
- Cluster taps zoom into the selected area.
- Time filters animate pin appearance and disappearance.
- The newest visit appears first in pin detail.
- Date-based rewind defaults to 10 AM and must be user-configurable.
- Location-based reminders must be individually switchable.
- Default location reminder radius is 200 m, adjustable from 100 m to 500 m.
- Rewind cards must support external sharing.
