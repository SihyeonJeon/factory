import SwiftUI

// vibe-limit-checked: 8 accessible CTA/grouping, 7 Korean monetization copy, 14 reusable tier-card layout
struct PremiumPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let tiers: [PremiumTier] = [
        .init(
            name: UnfadingLocalized.Settings.premiumTierFreeName,
            price: UnfadingLocalized.Settings.premiumTierFreePrice,
            badge: nil,
            features: UnfadingLocalized.Settings.tierFeatures(0)
        ),
        .init(
            name: UnfadingLocalized.Settings.premiumTierMonthly,
            price: UnfadingLocalized.Settings.premiumTierMonthlyPrice,
            badge: nil,
            features: UnfadingLocalized.Settings.tierFeatures(1)
        ),
        .init(
            name: UnfadingLocalized.Settings.premiumTierAnnual,
            price: UnfadingLocalized.Settings.premiumTierAnnualPrice,
            badge: UnfadingLocalized.Settings.premiumSavingBadge,
            features: UnfadingLocalized.Settings.tierFeatures(2)
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: UnfadingTheme.Spacing.lg) {
                    ForEach(tiers) { tier in
                        tierCard(tier)
                    }

                    Button(UnfadingLocalized.Settings.premiumComingSoon) {
                    }
                    .buttonStyle(.unfadingPrimaryFullWidth)
                    .disabled(true)
                    .accessibilityHint(UnfadingLocalized.Accessibility.premiumComingSoonHint)
                }
                .padding(UnfadingTheme.Spacing.xl)
            }
            .background(UnfadingTheme.Color.cream)
            .navigationTitle(UnfadingLocalized.Settings.premiumExplore)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(UnfadingLocalized.Common.cancel) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func tierCard(_ tier: PremiumTier) -> some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                    Text(tier.name)
                        .font(UnfadingTheme.Font.title3Bold())
                        .foregroundStyle(UnfadingTheme.Color.textPrimary)
                    Text(tier.price)
                        .font(UnfadingTheme.Font.subheadlineSemibold())
                        .foregroundStyle(UnfadingTheme.Color.primary)
                }
                Spacer()
                if let badge = tier.badge {
                    Text(badge)
                        .font(UnfadingTheme.Font.captionSemibold())
                        .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                        .padding(.horizontal, UnfadingTheme.Spacing.sm)
                        .padding(.vertical, UnfadingTheme.Spacing.xs)
                        .background(UnfadingTheme.Color.primary, in: Capsule())
                }
            }

            ForEach(tier.features, id: \.self) { feature in
                Label(feature, systemImage: "checkmark.circle.fill")
                    .font(UnfadingTheme.Font.subheadline())
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
            }
        }
        .padding(UnfadingTheme.Spacing.lg)
        .unfadingCardBackground(fill: UnfadingTheme.Color.sheet, radius: UnfadingTheme.Radius.card)
        .accessibilityElement(children: .combine)
    }
}

private struct PremiumTier: Identifiable {
    let id = UUID()
    let name: String
    let price: String
    let badge: String?
    let features: [String]
}
