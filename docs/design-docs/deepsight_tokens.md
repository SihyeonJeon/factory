# Deepsight Design Tokens

## Source Inventory

| Source | SHA-256 | Notes |
|---|---|---|
| `docs/design-docs/travel_deepsight/Unfading Prototype.html` | `sha256:df8fe6badd57d17805a36385c1d9f62efd4d964efca3aa7bdc8d9c2189cb471e` | Interactive web prototype. Contains the highest-signal token data in an embedded `THEME` object and screen scene list. |
| `docs/design-docs/travel_deepsight/check.png` | `sha256:cb14f4bb14080f84d8c1b8ef4cce095505f778548ab998a6514038da7242e614` | Eight-screen overview. Confirms screen list and high-level tokens shown in the right panel. |
| `docs/design-docs/travel_deepsight/debug.png` | `sha256:0bfe72e4668458114180ea91d60ae019c99e46994ea7326ba7ae33c855947d92` | Mostly black/low-signal image during this extraction pass. |

## Color Tokens

The prototype defines the following core theme values in `Unfading Prototype.html`.

| Prototype token | Value | Proposed semantic role | Existing contract mapping note |
|---|---:|---|---|
| `primary` | `#F5998C` | Warm coral primary action/accent | Candidate for `UnfadingTheme.primary`. |
| `primaryLight` | `#FAC7BC` | Soft coral highlight/background gradient stop | Candidate for a primary-light token. |
| `secondary` | `#C2B0DE` | Lavender secondary accent | Candidate for `UnfadingTheme.secondary`. |
| `secondaryLight` | `#E3D9F2` | Soft lavender highlight/background gradient stop | Candidate for a secondary-light token. |
| `card` | `#FFFAF5` | Cream card background | Candidate for card/background token. |
| `sheet` | `#FFF8F0` | Warm sheet background | Candidate for bottom-sheet surface token. |
| `surface` | `#FAF2EB` | Warm app surface/map-adjacent surface | Candidate for grouped surface token. |
| `textPrimary` | `#403833` | Primary warm dark text | Candidate for `UnfadingTheme.textPrimary`. |
| `textSecondary` | `#8C8078` | Secondary warm gray text | Candidate for `UnfadingTheme.textSecondary`. |
| `textTertiary` | `#B5A89E` | Tertiary/muted warm gray text | Candidate for tertiary text token. |
| `accentSoft` | `rgba(245,153,140,0.15)` | Soft primary tint | Candidate for selected/background tint token. |
| `chipBg` | `#F5EBE1` | Filter chip background | Candidate for chip/background token. |
| `divider` | `rgba(64,56,51,0.08)` | Hairline divider | Candidate for divider token. |

Additional repeated palette values appear in mock data and map styles:

| Value | Observed use |
|---:|---|
| `#8FB7A8` | Green member color, place/trip gradients, general-group mode accents. |
| `#E4B978` | Gold member color and warm photo/event gradients. |
| `#A9A1C7`, `#9A85C0` | Purple/lavender member and gradient values. |
| `#7B9FD4`, `#D48FB2`, `#8FA88B`, `#C7A77B`, `#7BAFB1` | Member/avatar colors. |
| `#F4ECE3` | Outer prototype/background canvas. |

Map-style palettes are present for multiple themes:

| Map theme area | Values observed |
|---|---|
| Default light map | `#F0EBE3`, `#F7F1E8`, `#D8E4E6`, `#FFFFFF`, `#E3E9D6`, `#E8DFD0`, `#8C8078` |
| Warm map | `#F4ECE3`, `#FAF2EB`, `#E0D4C6`, `#FFF8F0`, `#E8DFD0`, `#EEDFC9`, `#A8968A` |
| Vintage map | `#EADFCB`, `#F3E7CE`, `#D6BFA0`, `#FDF5E3`, `#D9CBA6`, `#E8D6B2`, `#8A7555` |
| Dark map | `#2A2320`, `#322A26`, `#1F1B19`, `#3F3631`, `#3A322C`, `#473C36`, `#8C8078` |

## Typography Tokens

| Source value | Observed use | Mapping note |
|---|---|---|
| `Gowun Dodum` | Primary Korean UI font in the prototype body and scene controls | Native implementation should map to semantic SwiftUI fonts, not a hardcoded custom size. |
| `Nunito` | Secondary Latin/UI font in prototype labels and notes | Native implementation should avoid hardcoded custom font unless product explicitly adopts it. |
| `JetBrains Mono` | Imported by prototype; no required product use identified from the visible scenes | No native token proposed yet. |
| `17`, `13`, `10.5` px examples | Scene rail title, buttons, caption-style text | Exact native values should be translated into semantic Dynamic Type styles during Phase 2 contract update. |

The existing coding conventions forbid hardcoded font sizes in Swift and require semantic styles or scaled metrics. Therefore these prototype typography values are extraction inputs, not direct Swift values.

## Spacing And Radius

Core radius tokens from the prototype `THEME` object:

| Prototype token | Value | Observed use |
|---|---:|---|
| `cardRadius` | `20` | Cards and large content modules. |
| `buttonRadius` | `16` | Buttons and medium controls. |
| `chipRadius` | `12` | Filter chips and compact controls. |
| `sheetRadius` | `28` | Bottom sheet top corners when not fully expanded. |

The `check.png` design panel confirms radii `20/16/12/8` and sheet snaps `22%/52%/88%`. The HTML `THEME` object confirms `20/16/12/28`; an explicit `8` token was visible in control padding/radius usage but not in the main `THEME` object.

Sheet snap points:

| State | Value | Observed behavior |
|---|---:|---|
| Collapsed | `22%` | Summary-only sheet state. |
| Default | `52%` | Main browsing state. |
| Expanded | `88%` | Cluster/marker filtered browsing state. |

Other repeated spacing values observed in the prototype include `8`, `12`, `14`, `18`, `20`, and `28` px in padding/gap/frame contexts. These are not yet proposed as final Swift spacing tokens because the source does not define a named spacing scale.

## Component Tokens

| Component family | Prototype token/behavior | Implementation mapping note |
|---|---|---|
| Bottom sheet | Warm sheet surface, 3 snap states, top radius `28`, expanded radius `0`, height animation `340ms cubic-bezier(0.32, 0.72, 0, 1)` | Maps to main map bottom-sheet contract. Swift implementation should preserve native gesture behavior. |
| Cards | Cream/warm card surfaces, radius `20`, subtle warm shadows/dividers | Requires centralized theme colors before screen work. |
| Buttons | Coral primary fill, radius `16`, white text/icons | Map to themed button styles, not inline colors. |
| Chips/segmented controls | `chipBg`, `chipRadius 12`, selected coral state | Map to filter chip and sheet tab components. |
| Pins/markers | Coral primary pin, selected marker scale/shadow, cluster count state | Map to `MemoryPinMarker` and map clustering visuals. |
| Avatars/member colors | Per-member accent palette | Needs domain-safe member color handling or deterministic palette. |
| Map controls | Warm sheet surface buttons above the sheet | Maps to current locate/reset controls. |
| Rewind card | Coral immersive gradient, white overlay text/actions | Maps to Rewind surface and shareable card concept. |
| Group mode presentation | Couple/general mode changes wording and cover gradients, not domain model | Preserve single group domain model. |

## Open Questions

- The active Swift workspace does not expose `UnfadingTheme.swift` during targeted search, while `ios-architecture.md` and `coding-conventions.md` require `UnfadingTheme`. Phase 2 must confirm whether to create, restore, or update the theme file before implementing tokens.
- Exact Dynamic Type mappings for prototype typography are not derivable from CSS pixel values alone.
- The role of the `8` radius value should be confirmed. It is visible in the design panel and some control usage, but not named in the prototype `THEME` object.
- The low-signal `debug.png` did not provide usable additional token data.
- Map palette tokens need product direction before native implementation: direct custom map styling may not map cleanly to the current iOS map stack.
