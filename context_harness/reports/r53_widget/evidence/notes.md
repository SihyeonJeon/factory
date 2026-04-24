# R53 Widget notes

- Current widget timeline is bundle-local sample data only. It intentionally does not touch Supabase or the app runtime store.
- Deferred App Group strategy for R58/R60:
  - add a shared app group entitlement to app + widget
  - persist a compact widget snapshot into shared defaults or a shared file container
  - keep WidgetKit reads read-only and fast; app writes the serialized "today memory" payload after memory mutations and on foreground refresh
  - move deep link routing remains `unfading://memory/<id>` and resolve into real detail navigation in R55
- Asset sharing in R53 uses direct references to `App/Assets.xcassets` and `App/Fonts` from the widget target, avoiding duplicate copies.
