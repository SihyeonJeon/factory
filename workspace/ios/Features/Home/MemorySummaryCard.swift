import SwiftUI

struct MemorySummaryCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// When a pin is selected on the map, the card shows that pin's title and
    /// short label. When nil, it shows the default sample "오늘의 리와인드" copy.
    var selectedPin: SampleMemoryPin? = nil
    var onDetailTap: (() -> Void)? = nil

    var body: some View {
        ScrollView(.vertical, showsIndicators: dynamicTypeSize.isAccessibilitySize) {
            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.lg - 2) {
                header

                Text(selectedPinBody)
                    .font(UnfadingTheme.Font.subheadline())
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                tagSection

                if let onDetailTap {
                    Button(action: onDetailTap) {
                        Label(UnfadingLocalized.Detail.detailCta, systemImage: "chevron.right.circle")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel(UnfadingLocalized.Detail.detailCta)
                }
            }
            .padding(UnfadingTheme.Spacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(maxHeight: dynamicTypeSize.isAccessibilitySize ? 320 : nil, alignment: .top)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(UnfadingLocalized.Accessibility.memorySummaryLabel(title: selectedPinTitle, body: selectedPinBody))
        .accessibilityHint(onDetailTap == nil ? "" : UnfadingLocalized.Accessibility.memorySummaryHint)
    }

    @ViewBuilder
    private var header: some View {
        Group {
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
        .accessibilityElement(children: .combine)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
            Text(selectedPinEyebrow)
                .font(UnfadingTheme.Font.captionSemibold())
                .foregroundStyle(UnfadingTheme.Color.textSecondary)
            Text(selectedPinTitle)
                .font(UnfadingTheme.Font.title3Bold())
                .foregroundStyle(UnfadingTheme.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
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

    // MARK: Selected-pin-aware content

    private var selectedPinEyebrow: String {
        selectedPin == nil ? UnfadingLocalized.Summary.tonightsRewind : UnfadingLocalized.Summary.selectedEyebrow
    }

    private var selectedPinTitle: String {
        selectedPin?.title ?? UnfadingLocalized.Summary.sampleTitle
    }

    private var selectedPinBody: String {
        if let short = selectedPin?.shortLabel {
            return UnfadingLocalized.Summary.selectedBodyTemplate(short: short)
        }
        return UnfadingLocalized.Summary.sampleBody
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
