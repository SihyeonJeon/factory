---
round: round_storekit_r1
stage: planning
status: decided
participants: [claude_code, codex]
decision_id: 20260423-r22-storekit
contract_hash: none
---

## Context

- R15 created `public.subscriptions` with select-self RLS and service-role write expectations.
- R22 must avoid App Store Connect dependency and use a local `.storekit` configuration for simulator run/test.
- Product IDs are monthly and yearly Unfading Premium subscriptions.
- Launchability target is client-side entitlement through StoreKit 2 `Transaction.currentEntitlements`.
- Server receipt validation and DB mirroring require an Edge Function and are deferred.

## Proposal

- Add a StoreKit configuration file with Korean storefront/locale and the two Premium recurring subscriptions.
- Configure the MemoryMap run/test scheme with `storeKitConfiguration: StoreKitConfiguration.storekit`.
- Add `SubscriptionStore` as a root environment object that loads products, listens for transaction updates, refreshes entitlements, purchases, and restores.
- Replace the existing placeholder premium sheet with a real Korean paywall.
- Update Settings to reflect current premium state and route free users to paywall or premium users to App Store subscription management.
- Add unit tests for stable constants and deterministic store behavior that does not require real purchases.

## Questions

- Does the round require server-side validation before launch?
  - Decision: no for v1 launchability; only client-side StoreKit entitlement is in scope.
- Should the subscription mirror table be written in this round?
  - Decision: no; Edge Function and signed receipt validation are a future round.

## Counter / Review

- Risk: client-side entitlement is not sufficient for expensive backend resources such as original-quality storage or AI generation.
- Risk: local StoreKit products do not prove App Store Connect products are configured correctly.
- Risk: XcodeGen scheme support for `storeKitConfiguration` must be verified by generation; if unsupported, a post-generation scheme patch or manual setting is required.

## Convergence

- Proceed with client-side StoreKit 2 for the launchable app path.
- Record the server validation gap explicitly in evidence notes so the deferred backend entitlement mirror is not lost.
- Keep purchase-flow tests limited to load/constant/error behavior; do not attempt real StoreKit purchases in unit tests.

## Decision

Implement `round_storekit_r1` with a local StoreKit test configuration, root `SubscriptionStore`, Korean paywall, Settings subscription state, and focused unit tests.

## Challenge Section

- Challenge: This round must not imply secure backend entitlement enforcement. Client-side StoreKit state is acceptable for local launchability and UI gating, but any future paid storage, original media, or AI quota must be guarded by server-validated subscription state written through service role.
- Rejected alternative: writing `public.subscriptions` directly from the client. This would violate the R15 service-role write model and would not provide trustworthy receipt validation.
