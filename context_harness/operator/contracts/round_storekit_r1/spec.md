# round_storekit_r1 Spec

## Goal

Wire launchable StoreKit 2 subscription state for Unfading Premium without App Store Connect dependency by using a local Xcode StoreKit configuration and client-side `Transaction.currentEntitlements`.

## Scope

- Add `StoreKitConfiguration.storekit` with monthly and yearly Unfading Premium recurring subscriptions:
  - `com.jeonsihyeon.memorymap.premium.monthly` at KRW 4,900/month.
  - `com.jeonsihyeon.memorymap.premium.yearly` at KRW 39,000/year.
- Configure the `MemoryMap` scheme run/test actions to use the local StoreKit configuration.
- Add `SubscriptionStore` as the client-side StoreKit 2 entitlement and purchase state owner.
- Replace the premium placeholder sheet with a real Korean paywall driven by `Product.products(for:)`.
- Inject `SubscriptionStore` at `MemoryMapApp` root and expose premium state/actions in Settings.
- Add Korean premium localized strings.
- Add unit coverage for product constants, entitlement-derived premium state, purchase error localization/equality, and load completion under the scheme StoreKit configuration.

## Non-Goals

- No App Store Connect product dependency for this round.
- No Edge Function receipt validation.
- No server write to `public.subscriptions`.
- No high-cost storage/AI entitlement enforcement based on the local client state.

## Entitlement Model

R22 uses StoreKit 2 client-side entitlement as the v1 launch path:

- `Transaction.currentEntitlements` populates current premium state.
- `Transaction.updates` refreshes state and finishes verified transactions.
- `AppStore.sync()` provides purchase restore.

The R15 `public.subscriptions` mirror remains intentionally deferred because it requires a service-role Edge Function and signed receipt/App Store Server validation.

## Acceptance

- Simulator run/test scheme uses `StoreKitConfiguration.storekit`.
- Free Settings state shows `무료 플랜` and opens the paywall via `프리미엄 보기`.
- Premium Settings state shows `프리미엄 활성` and exposes App Store subscription management.
- Paywall loads monthly/yearly products, includes restore, shows loading/error states, and keeps Korean UI copy.
- Accessibility identifiers exist:
  - `premium-monthly-button`
  - `premium-yearly-button`
  - `premium-restore-button`
- Existing tests continue to pass.
