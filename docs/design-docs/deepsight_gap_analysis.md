# Deepsight Gap Analysis

## Source Inventory

| Source | SHA-256 | Use in this analysis |
|---|---|---|
| `docs/design-docs/travel_deepsight/Unfading Prototype.html` | `sha256:df8fe6badd57d17805a36385c1d9f62efd4d964efca3aa7bdc8d9c2189cb471e` | Primary source for token values, scene list, interaction notes, and prototype behavior. |
| `docs/design-docs/travel_deepsight/check.png` | `sha256:cb14f4bb14080f84d8c1b8ef4cce095505f778548ab998a6514038da7242e614` | Confirms eight-screen overview and design panel tokens. |
| `docs/design-docs/travel_deepsight/debug.png` | `sha256:0bfe72e4668458114180ea91d60ae019c99e46994ea7326ba7ae33c855947d92` | Low-signal image; no additional extracted requirements. |

Reference contracts used:

- `docs/design-docs/design-revision-workflow.md`
- `context_harness/prd/ui_ux_screen_contract.md`
- `docs/design-docs/ios-architecture.md`
- `docs/references/coding-conventions.md`

Targeted Swift inventory used:

- `workspace/ios/App/RootTabView.swift`
- `workspace/ios/Features/Home/MemoryMapHomeView.swift`
- `workspace/ios/Features/Home/MemoryComposerSheet.swift`
- `workspace/ios/Features/Home/MemoryPinMarker.swift`
- `workspace/ios/Features/Home/MemorySummaryCard.swift`
- `workspace/ios/Features/Groups/GroupHubView.swift`
- `workspace/ios/Features/Rewind/RewindFeedView.swift`
- `workspace/ios/Features/Rewind/RewindMomentCard.swift`

## Screen Inventory

| Category | Current | Deepsight | Impact radius |
|---|---|---|---|
| Screen inventory | Product contract defines Main Memory Map, Memory Detail, Create/Edit Memory, Create/Edit Event, Group Creation/Mode Selection, Invitations/Member Management, Rewind and Calendar Surfaces. Active Swift targeted inventory shows `MemoryMapHomeView`, `MemoryComposerSheet`, `GroupHubView`, `RewindFeedView`, and supporting home/rewind components. | Prototype scene rail lists 8 scenes: Main Map, Cluster Selected, Pin Selected, Memory Detail, Memory Composer, Calendar, Rewind, Group Hub. | Current product contract already covers most concepts, but Deepsight splits map states into separate scenario surfaces and makes Calendar a full explicit screen. |
| Main map | Required contract: full-screen map, top controls, add-memory action, bottom sheet with collapsed/default/expanded states. | Main map scene keeps map-first layout and 3 sheet snaps. | Mostly preserve, but token/sheet behavior should become more explicit. |
| Cluster selected | Current contract requires cluster selection visual signal and bottom-sheet filtering. | Prototype sets cluster selection to expanded sheet, filtered context header, clear action, and "add memory to this cluster" affordance. | Needs sharper selected-cluster contract and UI state tests later. |
| Pin selected | Current contract requires marker selection and filtered sheet. | Prototype scales selected pin and raises sheet to place/memory context. | Requires marker state styling and filtered sheet behavior review. |
| Memory detail | Current contract requires event/place/time/contributors/content and cross-memory browsing. | Prototype emphasizes member-level `MemoryPost` cards, emotion tags, cost, location mini-map, and fixed previous/next bar within same event. | Current contract supports the concept but should name member contribution layout and fixed browsing affordance if adopted. |
| Memory composer | Current contract requires media input, event selection, place/time inference and confirmation. | Prototype includes photo grid, album/camera/file sources, inferred place/time confirmation ring, current-location substitution, and time wheel. | Strong alignment; design detail should refine required confirmation UI. |
| Calendar | Current contract groups Calendar under Rewind and Calendar Surfaces. Active `RootTabView` targeted read shows no Calendar tab in the current three-tab root. | Prototype includes a dedicated Calendar screen with month/year wheel picker, memory dots, selected-date event cards, and cost summary. | Navigation and screen inventory change if Calendar becomes first-class again. |
| Rewind | Current contract supports "N years ago today", optional place-sensitive rewind, shareable cards. Active Swift has `RewindFeedView`. | Prototype uses immersive single-place/photo rewind with glass action card and same-place reminder. | Current contract broadly aligns; visual treatment and reminder behavior need a follow-up slice. |
| Group Hub | Current contract covers group/mode creation and invitations/member management. Active Swift has `GroupHubView`. | Prototype combines cover, avatars, mode toggle, map theme, pin pack, member management, invitation, premium settings. | Current product areas exist but group hub becomes a richer screen and settings surface. |

## Navigation

| Category | Current | Deepsight | Impact radius |
|---|---|---|---|
| Root model | `ui_ux_screen_contract.md` allows tab root, stack root, modal flows, or hybrid. Targeted `RootTabView.swift` currently has three tabs: Map, Rewind, Groups. `ios-architecture.md` still describes a three-tab Map/Calendar/Settings shape, which is stale against the targeted Swift read. | Prototype has an internal tab bar in map/calendar/group contexts and scene-level routes for Map, Calendar, Rewind, Group. Calendar appears as a first-class screen. | Requires a navigation contract update before implementation. Calendar placement must be decided explicitly. |
| Map state routing | Current contract treats cluster/marker as first-class map state. | Prototype scene model treats default map, cluster selected, and pin selected as separate states with snap mapping. | Implementation can remain one map screen with state, but brief should name the three scenarios. |
| Composer entry | Current contract allows FAB, selected place, selected event, and detail follow-up. | Prototype uses FAB and selected-context "add memory" actions. | Aligns; selected-context entry should be included in composer slice. |
| Detail flow | Current contract requires full detail surface. | Prototype opens detail from sheet cards and returns to cluster context. | Implementation should preserve origin context for back navigation. |
| Group switching | Current contract includes group/member management. | Prototype includes group picker overlay and group hub settings. | Requires decision whether group switcher lives in top chrome, group hub, or both. |

## Component Tokens

| Category | Current | Deepsight | Impact radius |
|---|---|---|---|
| Theme source | `coding-conventions.md` requires `UnfadingTheme.*` and forbids inline colors. `ios-architecture.md` lists `UnfadingTheme.swift`, but targeted search did not find an active `UnfadingTheme` file in `workspace/ios/`. | Prototype `THEME` object defines primary, secondary, card, sheet, surface, text, chip, divider, and radius tokens. | First implementation slice should resolve theme source of truth before screen work. |
| Color palette | Current code targeted search shows system colors and `Color.accentColor` in active files. | Prototype defines warm coral/lavender/cream palette and warm map surfaces. | Broad visual refactor if adopted. |
| Radius scale | Current targeted Swift shows radii 16, 22, 28 in components. | Prototype names 20, 16, 12, 28; design panel also mentions 8. | Need tokenized radius scale and mapping to existing card/button/chip/sheet shapes. |
| Sheet snaps | Current contract says collapsed/default/expanded but exact heights may vary. | Prototype names 22%/52%/88% snaps. | Exact snap points should be contract-updated if chosen. |
| Map styling | Current contract says premium native maps product. | Prototype includes multiple stylized map palettes and mode/theme options. | Native feasibility needs implementation review before promising exact map colors. |

## Interaction

| Category | Current | Deepsight | Impact radius |
|---|---|---|---|
| Bottom sheet | Current contract requires collapsed/default/expanded browsing states. | Prototype maps default map to default snap, cluster/pin to expanded snap, and uses tap cycling in the prototype. | Sheet state transitions should be specified for cluster and pin selection. |
| Cluster selection | Current contract says select, filter, optionally zoom/focus. | Prototype explicitly raises sheet to 88%, filters content, shows selected context header, and provides clear action. | Adds concrete behavior to existing contract. |
| Pin selection | Current contract says visual signal and filtered sheet. | Prototype scales selected marker, adds coral shadow/ring, and raises sheet. | Requires marker visual state token and interaction slice. |
| Composer confirmation | Current contract requires confirmation of inferred place. | Prototype shows "confirmation needed" ring and disables save until confirmation. | Strong current alignment; UI specifics can be codified. |
| Calendar | Current contract allows varied calendar UX. | Prototype uses month/year wheel picker and day dots. | Calendar UX should be contract-updated if adopted. |
| Rewind | Current contract supports place-sensitive rewind. | Prototype includes same-place reminder and shareable card flow. | Reminder trigger and permissions need later review. |

## Copy

| Category | Current | Deepsight | Impact radius |
|---|---|---|---|
| Language | Coding conventions require Korean user-facing text. | Prototype UI text is primarily Korean with some product/technical labels in side panels such as `private map diary`. | App-facing text remains Korean; prototype side-panel English is not app copy by itself. |
| Mode wording | Current contract allows intimate couple wording and neutral group wording. | Prototype notes mode-specific curation tone and group mode changes presentation only. | Aligns with existing mode rules. |
| Map selected context | Current contract requires user to understand selected geographic context. | Prototype uses cluster/place context headers and clear action. | Copy contract should name selected-context labels and clear behavior. |
| Composer copy | Current contract requires confirmation but not exact labels. | Prototype includes "확인 필요" style semantics for inferred metadata. | Exact Korean labels should be determined in implementation brief. |

## Accessibility

| Category | Current | Deepsight | Impact radius |
|---|---|---|---|
| Baseline rules | Coding conventions require Korean labels/hints, 44pt targets, Dynamic Type, semantic fonts. | Prototype is web/CSS and does not provide VoiceOver order or native accessibility labels. | Accessibility must be designed during native implementation, not inferred from prototype. |
| Touch targets | Current rules require minimum 44pt interactive targets. | Prototype visual controls appear compact in some scene rail/tweak controls, but those are prototype shell controls, not app surfaces. | Native app controls must be checked per screen slice. |
| Dynamic Type | Current rules forbid hardcoded Swift font sizes. | Prototype uses CSS pixel sizes and imported fonts. | Swift implementation must translate to semantic fonts rather than copy pixel values. |
| VoiceOver order | Current rules require logical reading order. | No usable VoiceOver script is present in Deepsight inputs. | Each screen implementation slice needs VoiceOver acceptance criteria. |

## Impacted Contracts

| Document | Sections likely impacted | Reason |
|---|---|---|
| `context_harness/prd/ui_ux_screen_contract.md` | Global Navigation Model; Screen 1 Main Memory Map; Screen 2 Memory Detail; Screen 3 Create/Edit Memory; Screen 7 Rewind and Calendar Surfaces; Mode-Specific Presentation Rules | Deepsight refines navigation, sheet states, selected map contexts, calendar, rewind, and group mode presentation. |
| `docs/design-docs/ios-architecture.md` | Structure; Design Principles | Current architecture doc appears stale against active `RootTabView.swift` and theme file search; it should be reconciled before implementation. |
| `docs/references/coding-conventions.md` | Style rules; file structure contract | Token naming and centralized theme discipline need concrete token additions once product approves palette. |
| Future acceptance doc | New Deepsight/HF acceptance file | The redesign affects more than three screens, so a new acceptance file or round-specific criteria should be created before Swift work. |

## Open Questions

- Should Calendar become a root tab/surface again, or remain reachable from map/rewind flows? Current targeted Swift shows Map/Rewind/Groups tabs.
- Does the project currently have an active `UnfadingTheme.swift` file? Targeted search found references in docs but not the Swift workspace.
- Are Deepsight map palettes intended for native map rendering, or are they visual direction only?
- Should sheet snap points be exact percentages `22/52/88`, or native-feeling approximate states?
- Should Group Hub absorb app settings/premium features, or should settings remain a separate surface?
- What are the final Korean app-copy strings for selected cluster, selected pin, inferred place confirmation, and rewind reminder?
- Is `debug.png` expected to contain useful design information? It was low-signal in this extraction pass.
