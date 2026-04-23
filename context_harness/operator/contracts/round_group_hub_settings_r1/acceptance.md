# round_group_hub_settings_r1 Acceptance

- Settings uses native `List` + `NavigationLink` to open Group Hub and exposes `settings-groups-row`.
- Group Hub exposes `group-hub` and `group-hub-switch-group` accessibility identifiers.
- Group Hub shows group name, mode, started date, member count, member rows, invite link/QR placeholder, appearance toggles, notification toggles, iCloud status, export CTA, leave/delete warnings.
- Korean user-facing strings live in `UnfadingLocalized`.
- `testGroupHubFromSettings` has no unconditional skip.
- `GroupHubTests` covers member count format, role label mapping, and warning dialog flag.
