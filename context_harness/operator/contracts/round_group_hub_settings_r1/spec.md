# round_group_hub_settings_r1 Spec

## Scope

- Replace Settings group entry with a native `List` row backed by `NavigationLink`.
- Expand Group Hub to cover group overview, started date, members with general-group role labels, group switching, invite link/QR placeholder, danger confirmations, appearance placeholders, notification toggles, and data CTA.
- Extend Korean copy under `UnfadingLocalized.GroupHub`.
- Reactivate `testGroupHubFromSettings`.
- Extend `GroupHubTests` for member-count copy, role labels, and warning dialog state.

## Non-goals

- No backend mutation for leave/delete in this round; warning state and CTA are wired, server operations remain future backend work.
- No real QR generation or export ZIP/JSON implementation; these remain placeholders per R35/R49 scope.
