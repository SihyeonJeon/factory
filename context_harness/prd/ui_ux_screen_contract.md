# UI/UX Screen Contract

## Purpose

This document defines the screen-level product contract for the map-first memory app.

It is intentionally written for harness execution rather than pixel locking.
Agents should treat this file as:
- a contract for user-facing goals and non-negotiable behavior
- a guardrail for navigation, state relationships, and native expectations
- not a frozen wireframe or visual prescription

## Agent Autonomy Contract

The implementing and reviewing agents retain strong autonomy over UI/UX execution.

Agents may change:
- exact component composition
- wording details
- section ordering inside adaptive curation
- gesture thresholds and animation tuning
- navigation transitions
- whether a browsing shortcut should happen in-sheet or in-detail
- visual hierarchy, as long as it remains native-feeling and HIG-safe

Agents may not change without updating product inputs:
- the map-first product direction
- the bottom sheet as a primary browsing surface
- the event hierarchy `Group -> DateEvent -> Memory -> MemoryPost`
- the couple/general-group dual-mode product shape
- required user confirmation for inferred place before save
- the principle that users can correct place via search or current location

If an agent finds a more native or more efficient interaction than the examples below, it should implement that alternative and record the reasoning in its delivery report.

## Product Shape

The app is a private map diary for couples and recurring groups.

The core exploratory model is:
- map as the main spatial surface
- bottom sheet as the main gallery browser
- detail page as the deeper reading and editing surface

The canonical data hierarchy is:
- `Group`
- `DateEvent`
- `Memory`
- `MemoryPost`

Behavioral meaning:
- `Group`: the shared space, either couple mode or general group mode
- `DateEvent`: the container for one day by default, with optional explicit promotion to a multi-day trip
- `Memory`: a specific moment, stop, or recordable memory node inside the event
- `MemoryPost`: each member's own contribution of photos, text, and reaction context to that memory

## Global Navigation Model

The preferred high-level model is:
- main map surface
- memory creation and editing flows
- memory detail flow
- event detail or event management flow when needed
- group and member management flow

Agents may decide whether the app uses:
- a tab-root plus pushed detail screens
- a stack-root with modal creation flows
- or a hybrid

The resulting structure must remain obviously iOS-native.

## Screen 1: Main Memory Map

### Purpose

This is the app's primary home and should feel closer to a premium native maps product than to a feed.

### Required Layers

The main screen should preserve four conceptual layers:
- full-screen map background
- floating top controls
- floating add-memory action
- foreground bottom sheet

Agents may restyle the layers, but the user must still perceive them as separate interaction planes.

### Top Controls

The top area should support:
- group selection
- place search or scoped location search
- lightweight context about the active group or mode when useful

In `couple` mode, wording may feel more intimate.
In `general_group` mode, wording should remain neutral and group-oriented.

### Map Behavior

The map should:
- show memory markers
- support clustering
- react smoothly to pan and zoom
- treat clusters, markers, and selected contexts as first-class state

Cluster selection must:
- visually signal selection
- filter the bottom sheet to the represented memory set
- optionally zoom or refine focus if that improves spatial comprehension

Marker selection must:
- visually signal selection
- filter the bottom sheet to the relevant place or memory context
- raise the sheet into a useful browsing state

### Bottom Sheet Role

The bottom sheet is not a temporary drawer.
It is the app's primary gallery browser.

It should support three browsing states:
- collapsed summary
- default browsing
- expanded browsing

Exact heights and gesture tuning may vary if agents find a more native solution.

### Bottom Sheet Default State

When no marker or cluster is selected, the sheet should surface adaptive curation.

The curation system may choose from signals such as:
- rewind or anniversary moments
- recent shared activity
- place bundles
- event bundles
- dense contribution clusters
- mode-specific emotional relevance

The exact ordering should remain algorithmic and adjustable.

### Bottom Sheet Selected State

When a cluster or marker is selected, the sheet should switch from generic curation to filtered browsing.

The user should understand:
- what geographic context is selected
- whether the list is scoped to a cluster, place, or event slice
- how to dismiss that selection and return to general exploration

### Content Grouping

The sheet should group content in a way that feels comparable to iPhone Photos event grouping.

The grouping may be:
- event-first, then memories
- date-first, then memory cards
- place-first, then event snippets

Agents should pick the most comprehensible structure.

### Tap Behavior

Tapping a memory card should open a dedicated memory detail page.

If a more efficient intermediate transition exists, agents may use it, but the user must still be able to reach a full detail surface without friction.

## Screen 2: Memory Detail

### Purpose

This is the deeper reading surface for one memory.
It should support immersive browsing while preserving the shared structure of contributions.

### Required Information

The detail page must make it clear:
- which event this memory belongs to
- where it happened
- when it happened
- who contributed
- what the main memory content is

### Contribution Model

The page should allow multiple users to contribute under the same memory.

At minimum, the page must support:
- viewing the aggregate memory
- viewing each member's contribution
- adding another contribution when allowed

Agents may decide whether contributions are displayed as:
- stacked cards
- sections by user
- a timeline
- a mixed gallery plus text layout

### Cross-Memory Browsing

The detail page should support moving to nearby or related memories when that clearly improves browsing flow.

Possible relationships:
- same event
- same place
- adjacent time
- same cluster context

Agents may choose swipe, pager, next/previous affordances, or another native-feeling pattern.

## Screen 3: Create Or Edit Memory

### Purpose

This flow must make memory creation feel quick, reliable, and metadata-aware.

### Entry Paths

Possible entry points include:
- floating add button
- selected place context
- selected event context
- memory detail follow-up action

Agents may choose the exact entry architecture.

### Media Input

The user must be able to add media from:
- photo library
- document picker
- in-app camera capture

If the user captures now, the app should attach capture time and location metadata whenever permissions allow.

### Event Selection

Memory creation must either:
- attach the memory to an existing `DateEvent`
- or allow inline creation of a new `DateEvent`

Default event behavior:
- single-day event by default
- explicit promotion path for multi-day travel or trip events

The app must not silently infer multi-day events without user intent.

### Place Inference And Confirmation

When media metadata includes location, the creation flow should:
1. derive a candidate coordinate
2. convert it into a human-readable place label or address when possible
3. show that place candidate in the place field
4. require user confirmation before final save

If the inferred place is wrong, the user must be able to:
- search for a place
- manually replace the place label if the chosen UX supports it
- or set the place to the device's current location

The stored representative coordinate should stay stable unless explicitly changed.

### Time Inference And Confirmation

When media metadata includes time, the creation flow should prefill it.
The user must still be able to replace it with the device's current time or another chosen time.

### Cost Field

Cost remains optional in all modes.
Agents may decide whether cost lives at:
- event level
- memory level
- or both with a clear primary source

The chosen solution should minimize confusion.

## Screen 4: Create Or Edit Event

### Purpose

This is the container-definition flow for dates, meetups, and trips.

### Required Behaviors

The event flow must support:
- title or event naming
- date selection
- optional explicit multi-day span
- optional summary fields
- optional cost or budgeting context if the chosen architecture places it here

In couple mode, wording may lean toward date or anniversary framing.
In general-group mode, wording should stay meetup or trip oriented.

## Screen 5: Group Creation And Mode Selection

### Purpose

This flow determines the social container and the UI mode.

### Required Behaviors

The group creation flow must support:
- required name
- optional image
- optional intro
- explicit selection between `couple` and `general_group`

The chosen mode should influence later presentation and curation, but should not fork the domain model into separate app architectures.

## Screen 6: Invitations And Member Management

### Required Behaviors

The group social layer must support:
- invite via code or link
- invitation expiry handling
- member list
- owner or admin actions where applicable
- group deletion or management actions with safe confirmation

This flow does not need to dominate the app, but it must remain trustworthy and native.

## Screen 7: Rewind And Calendar Surfaces

### Purpose

These surfaces help users revisit memory over time.

### Rewind

The app should support:
- "N years ago today"
- optional place-sensitive rewind
- shareable rewind cards

### Calendar

The app should support a calendar-oriented view of past activity.

The chosen calendar UX may vary, but it should be able to surface:
- date-linked memories
- date-linked photo presence
- optional cost context

## Mode-Specific Presentation Rules

### Couple Mode

May emphasize:
- intimacy
- anniversaries
- date-based wording
- emotional summaries
- warm curation labels

### General Group Mode

May emphasize:
- shared history
- meetup or trip wording
- member participation
- collective memories

### Shared Rule

The two modes may differ in presentation, copy, and recommendation emphasis, but should still feel like the same product family.

## Evaluation Rules For Agents

When evaluating a proposed UI/UX solution, agents should prefer the option that best satisfies:
- native iOS feel
- map-to-sheet clarity
- low confusion during creation
- comprehensible event and memory grouping
- low-friction correction of inferred metadata
- HIG safety

Agents should reject designs that:
- turn the map into a decorative secondary layer
- make the bottom sheet feel like a generic modal
- expose raw coordinates as the primary place UX
- hide the event hierarchy from the user
- force the user into confusing place-confirmation behavior
- overload the main screen with too many simultaneous surfaces

## Open Design Latitude

The following are intentionally left open for agent judgment:
- exact sheet snap values
- the strongest gallery grouping structure
- whether detail navigation is swipe-based or button-based
- whether event creation is inline, modal, or pushed
- whether place search uses Apple-native search, external services, or a hybrid
- the exact curation algorithm
- whether calendar lives as a tab, pushed page, or alternate mode

This latitude is deliberate.
The harness should optimize for good expert execution, not for blindly freezing an early non-expert wireframe.
