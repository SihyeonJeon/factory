# Unfading Monetization Strategy

**Product:** Korean couple/group map diary for memory capture, place-based browsing, Rewind, calendar, group history, and shareable diary artifacts.

**Positioning:** private map diary for relationships and small groups. No ads. Premium pays for storage, customization, richer exports, and quality-of-life automation, not basic emotional memory keeping.

## Business Model

Freemium subscription with optional one-time paid exports.

### Free Tier

Target: couples, close friends, and small groups trying the product.

Included:

- 1 active couple or group space
- up to 5 members
- limited monthly new memories, recommended launch cap: 30 memories/month
- basic map style
- core map pins, composer, Rewind basics, calendar basics
- basic media compression/storage cap
- no ads

Purpose:

- let users build emotional history before monetization,
- avoid paywalling the core diary loop,
- create natural upgrade moments at storage, export, theme, and larger group boundaries.

### Premium Individual / Couple

Target: couples and small groups with frequent use.

Proposed price:

- KRW 4,900/month
- KRW 49,000/year

Premium features:

- unlimited memories within fair-use storage policy
- custom map themes: warm, vintage, dark, seasonal, trip-specific
- AI-enhanced Rewind captions and memory summaries
- shareable diary book exports: PDF/video/card
- higher storage and original-quality media options
- anniversary reminders and location-based revisit prompts
- premium pin packs and cover styles
- priority support

### Premium Group / Family

Target: friend groups, families, clubs, trips.

Proposed price:

- KRW 8,900/month per group
- KRW 89,000/year per group

Included:

- 6+ members
- group roles/admin controls
- shared storage pool
- group diary book exports
- event/trip collections
- premium map themes and group cover styles
- priority support

### One-Time Purchases

Useful where users resist subscriptions:

- Diary book export: KRW 3,900-9,900 depending on format/length
- Seasonal map/pin pack: KRW 1,900-3,900
- Trip archive export bundle: KRW 6,900

One-time purchases should not replace subscription value; they monetize high-intent moments.

## Premium Feature Ladder

| User moment | Upgrade hook | Premium value |
|---|---|---|
| User reaches monthly memory limit | "이번 달 추억이 가득 찼어요" | unlimited memories |
| Couple anniversary approaches | Rewind/anniversary reminder | AI-enhanced recap and export |
| Group has 6th member | member cap reached | family/group tier |
| User customizes map often | theme preview | premium map themes |
| User shares screenshots | export prompt | diary book/video/card export |
| User stores many photos | storage meter | higher storage/original quality |

## Retention Hooks

- Anniversary reminders: 100 days, 1 year, first trip, first place.
- Rewind push: "1년 전 오늘, 여기에서 남긴 추억".
- Place revisit prompt: when near a saved place, suggest opening past memory.
- Gentle streak-like loops: weekly memory recap, not daily pressure.
- Group nudges: "민재가 새 반응을 남겼어요", "이번 여행 앨범이 완성됐어요".
- Seasonal diary: month-end and year-end memory maps.
- Export milestones: after 50 memories, after first trip, after anniversary.

Avoid manipulative streak mechanics. The product tone should feel intimate and respectful.

## Korean Market Considerations

### Payments

Default launch path: Apple In-App Purchase / StoreKit 2.

Reasons:

- best App Store review fit,
- built-in subscription management,
- lower operational burden for refunds, tax handling, family purchase expectations,
- less checkout friction for early launch.

South Korea alternative payment option:

- Apple provides a Korea-specific StoreKit External Purchase Entitlement for apps distributed solely in South Korea: https://developer.apple.com/support/storekit-external-entitlement-kr
- Alternative PSPs may include Korean providers such as KCP, Inicis, Toss, or NICE, but the app must follow Apple's external purchase modal/API requirements and may need a Korea-only binary.
- Alternative payment reduces some App Store control but adds support/refund/subscription-management burden and can still carry Apple commission/service-fee complexity.

Recommendation:

- Launch with StoreKit 2 only.
- Revisit Korea-only external purchase after product-market fit and subscription volume justify operational overhead.

### Payment Methods And Local Expectations

Korean users expect:

- KakaoPay, Naver Pay, Toss, credit/debit card, carrier billing, and easy cancellation experiences.
- If using StoreKit, explain subscription management clearly in Korean and deep-link to App Store subscription management.
- If later using external payment, provide Korean receipts, cancellation, refund, and customer-support flows equivalent to app-store expectations.

### Tax And Compliance

- Price tiers must account for VAT-inclusive consumer pricing.
- Digital subscription receipts and refund policies must be clear in Korean.
- Family/group data and photos are sensitive; premium storage/AI features must have explicit privacy copy.
- AI-enhanced Rewind should disclose when generated summaries/captions are AI-assisted.

## Pricing Rationale

Initial KRW pricing should be low enough for couples but high enough to pay for media storage and AI features.

| Tier | Monthly | Annual | Notes |
|---|---:|---:|---|
| Free | KRW 0 | KRW 0 | core loop, limited monthly memory creation |
| Premium Couple/Small Group | KRW 4,900 | KRW 49,000 | annual gives ~17% discount |
| Premium Group/Family | KRW 8,900 | KRW 89,000 | supports 6+ members/shared storage |

Consider launch promo:

- 30-day trial for annual plan
- early-user lifetime annual discount for first 1,000 paid users
- free export credit after first paid month

## Rough Revenue Model

Assumptions for first launch year:

- 50,000 installs
- 35% activation to first memory: 17,500 activated users
- 20% reach 10+ memories: 10,000 engaged users
- 5% paid conversion from engaged users: 500 paid subscribers
- blended ARPPU: KRW 5,500/month

Monthly recurring revenue estimate:

- 500 × KRW 5,500 = KRW 2,750,000 MRR

Upside scenario:

- 150,000 installs
- 30,000 engaged users
- 8% paid conversion
- 2,400 paid subscribers × KRW 5,500 = KRW 13,200,000 MRR

CAC guidance:

- If blended monthly gross margin per paid user after platform fees/storage is ~KRW 3,000-4,000, paid CAC should stay below KRW 12,000-18,000 unless annual conversion is strong.
- Early acquisition should prioritize organic TikTok/Instagram/Reels couples/travel content, university groups, wedding/anniversary communities, and referral loops before paid ads.

## Premium Ethics

Principles:

- No ads in the free tier.
- Do not paywall private memory viewing after users create data.
- Do not hold user memories hostage; exports/downloads should remain possible at least in basic form.
- Premium should improve quality, volume, customization, automation, and export richness.
- AI features should assist writing/recap, not invent false memories.

Free users should feel respected; premium should feel like a better way to preserve something meaningful.

## Launch-Ready Checklist

### Product

- Free-tier memory limit copy in Korean.
- Upgrade screen with transparent plan comparison.
- Storage usage meter.
- Premium theme preview.
- Export preview watermark for free users.
- Subscription management screen.
- Privacy copy for photos, locations, AI summaries, and group data.

### StoreKit 2

- Product IDs for monthly/annual couple premium.
- Product IDs for monthly/annual group premium.
- Optional consumable/non-consumable export products.
- StoreKit 2 purchase flow.
- Transaction listener and entitlement cache.
- Restore purchases.
- App Store subscription management deep link.
- Server-side receipt or App Store Server API validation before high-cost storage/AI entitlements.
- Grace-period and billing-retry handling.

### Backend

- Entitlement table keyed by user/group.
- Storage quota enforcement.
- Group member count enforcement.
- Export job queue.
- AI recap quota/rate limit.
- Audit log for premium entitlement changes.

### App Review / Legal

- Korean subscription terms.
- Privacy policy covering location, photos, group data, and AI processing.
- Data deletion and export path.
- Clear cancellation instructions.
- If using external payment later: Korea-only entitlement, modal sheet, PSP compliance, and support/refund policy.

## Recommended Launch Offer

Launch with:

- Free: 30 memories/month, up to 5 members, basic map.
- Premium Couple/Small Group: KRW 4,900/month or KRW 49,000/year.
- Premium Group/Family: KRW 8,900/month or KRW 89,000/year.
- One free diary-card export after first paid month.

The first premium upsell should appear at a meaningful moment: anniversary/revisit/export, not immediately at onboarding.
