# round_storekit_r1 Evidence Notes

## StoreKit Configuration

- Added `workspace/ios/StoreKitConfiguration.storekit` with Korean locale/storefront and two recurring subscriptions:
  - `com.jeonsihyeon.memorymap.premium.monthly`
  - `com.jeonsihyeon.memorymap.premium.yearly`
- `workspace/ios/project.yml` configures the `MemoryMap` scheme run and test actions with `storeKitConfiguration: StoreKitConfiguration.storekit`.
- The installed XcodeGen version writes the StoreKit reference for `LaunchAction` but omits it from `TestAction`; `workspace/ios/scripts/apply_storekit_scheme.sh` is registered as `options.postGenCommand` to patch the generated shared scheme after generation.

## Entitlement Strategy

- R22 intentionally uses client-side StoreKit 2 entitlement through `Transaction.currentEntitlements`.
- `SubscriptionStore` also listens to `Transaction.updates`, finishes verified transactions, and calls `AppStore.sync()` for restore.
- This is sufficient for v1 launchability and simulator/local StoreKit testing because StoreKit 2 provides signed transaction verification on device and entitlement sync across Apple account/iCloud purchase state.

## Deferred Server Validation

- Server-side validation is deferred.
- The R15 table `public.subscriptions(user_id pk, product_id, original_transaction_id, purchased_at, expires_at, status, auto_renew, environment, updated_at)` remains a future mirror.
- A future round must add:
  - Edge Function receipt/App Store Server validation.
  - Service-role writes to `public.subscriptions`.
  - Backend enforcement for premium storage, original-quality media, AI Rewind, and other costly entitlements.
- The client must not write `public.subscriptions` directly.

## Test Boundary

- Unit tests cover constants, premium derivation, purchase error localization/equality, and `loadProducts()` completion.
- Actual purchase flow is not unit-tested because it requires StoreKit runtime dialogs and transaction environment behavior.
- `xcodegen generate` completed after the post-generation scheme patch was added.
- Requested `xcodebuild test` was started with `.deriveddata/r22/Test-R22.xcresult`, then stopped at package resolution because SPM fetches to `github.com` failed with DNS errors. This matches the round instruction to stop if SPM fetch blocks.
