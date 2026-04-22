import SwiftUI

struct MemorySummaryCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView(.vertical, showsIndicators: dynamicTypeSize.isAccessibilitySize) {
            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.lg - 2) {
                header

                Text(UnfadingLocalized.Summary.sampleBody)
                    .font(UnfadingTheme.Font.subheadline())
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                tagSection
            }
            .padding(UnfadingTheme.Spacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(maxHeight: dynamicTypeSize.isAccessibilitySize ? 320 : nil, alignment: .top)
        .unfadingCardBackground(
            fill: UnfadingTheme.Color.sheet,
            radius: UnfadingTheme.Radius.sheet,
            material: .regular
        )
    }

    @ViewBuilder
    private var header: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
                titleBlock
                peopleBadge
            }
        } else {
            HStack(alignment: .top, spacing: UnfadingTheme.Spacing.md) {
                titleBlock
                Spacer(minLength: UnfadingTheme.Spacing.md)
                peopleBadge
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
            Text(UnfadingLocalized.Summary.tonightsRewind)
                .font(UnfadingTheme.Font.captionSemibold())
                .foregroundStyle(UnfadingTheme.Color.textSecondary)
            Text(UnfadingLocalized.Summary.sampleTitle)
                .font(UnfadingTheme.Font.title3Bold())
                .foregroundStyle(UnfadingTheme.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var peopleBadge: some View {
        Label(UnfadingLocalized.Summary.friendCount, systemImage: "person.3.fill")
            .font(UnfadingTheme.Font.footnoteSemibold())
            .foregroundStyle(UnfadingTheme.Color.textPrimary)
            .padding(.horizontal, UnfadingTheme.Spacing.sm + 2)
            .padding(.vertical, UnfadingTheme.Spacing.sm)
            .frame(minHeight: 44)
            .background(
                UnfadingTheme.Color.primarySoft,
                in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.button, style: .continuous)
            )
            .fixedSize(horizontal: false, vertical: true)
    }

    private var tagSection: some View {
        ViewThatFits(in: .vertical) {
            HStack(spacing: UnfadingTheme.Spacing.md) {
                MemoryTag(title: UnfadingLocalized.Summary.joyTag, systemImage: "sparkles")
                MemoryTag(title: UnfadingLocalized.Summary.nightOutTag, systemImage: "moon.stars.fill")
                MemoryTag(title: UnfadingLocalized.Summary.photoSetTag, systemImage: "photo.on.rectangle")
            }

            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.sm + 2) {
                MemoryTag(title: UnfadingLocalized.Summary.joyTag, systemImage: "sparkles")
                MemoryTag(title: UnfadingLocalized.Summary.nightOutTag, systemImage: "moon.stars.fill")
                MemoryTag(title: UnfadingLocalized.Summary.photoSetTag, systemImage: "photo.on.rectangle")
            }
        }
    }
}

private struct MemoryTag: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(UnfadingTheme.Font.footnoteSemibold())
            .foregroundStyle(UnfadingTheme.Color.textPrimary)
            .padding(.horizontal, UnfadingTheme.Spacing.md)
            .padding(.vertical, UnfadingTheme.Spacing.sm)
            .frame(minHeight: 44)
            .background(
                UnfadingTheme.Color.primarySoft,
                in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.button, style: .continuous)
            )
            .fixedSize(horizontal: false, vertical: true)
    }
}
