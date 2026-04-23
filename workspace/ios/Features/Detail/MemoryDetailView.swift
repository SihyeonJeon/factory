import SwiftUI

// vibe-limit-checked: 8 a11y/44pt/grouping, 1 single detail surface, 7 runtime-fidelity sections, 11 sample-detail mapping
struct MemoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPin: SampleMemoryPin

    init(pin: SampleMemoryPin) {
        _currentPin = State(initialValue: pin)
    }

    private var detail: SampleMemoryDetail? {
        currentPin.detail()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xl) {
                photoCarousel
                titleLocationTimeCard
                moodSection
                noteSection
                contributionsSection
            }
            .padding(UnfadingTheme.Spacing.xl)
        }
        .background(UnfadingTheme.Color.sheet)
        .navigationTitle(UnfadingLocalized.Detail.navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    move(delta: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(UnfadingLocalized.Detail.previousButton)

                Button {
                    move(delta: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(UnfadingLocalized.Detail.nextButton)
            }
        }
    }

    private var photoCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: UnfadingTheme.Spacing.md) {
                if photoStoragePaths.isEmpty == false {
                    ForEach(photoStoragePaths, id: \.self) { path in
                        RemoteImageView(storagePath: path)
                        .frame(width: 220, height: 165)
                        .clipShape(RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous))
                        .accessibilityHidden(true)
                    }
                } else {
                    ForEach(photoSymbols, id: \.self) { symbol in
                        RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [UnfadingTheme.Color.primarySoft, UnfadingTheme.Color.primary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 220, height: 165)
                            .overlay {
                                Image(systemName: symbol)
                                    .font(.largeTitle.weight(.semibold))
                                    .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                            }
                            .accessibilityHidden(true)
                    }
                }
            }
        }
    }

    private var titleLocationTimeCard: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
            Text(UnfadingLocalized.Detail.title(for: currentPin))
                .font(UnfadingTheme.Font.title3Bold())
                .foregroundStyle(UnfadingTheme.Color.textPrimary)

            Label(UnfadingLocalized.Detail.place(for: currentPin), systemImage: "mappin.and.ellipse")
            Label(UnfadingLocalized.Detail.time(for: currentPin), systemImage: "clock")

            if let costText {
                Label(costText, systemImage: "wonsign.circle")
            }
        }
        .font(UnfadingTheme.Font.subheadline())
        .foregroundStyle(UnfadingTheme.Color.textSecondary)
        .padding(UnfadingTheme.Spacing.lg)
        .unfadingCardBackground(fill: UnfadingTheme.Color.cream)
        .accessibilityElement(children: .combine)
    }

    private var moodSection: some View {
        SectionBlock(title: UnfadingLocalized.Detail.moodLabel) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: UnfadingTheme.Spacing.sm) {
                    ForEach(detail?.moodTagIDs ?? [], id: \.self) { id in
                        UnfadingFilterChip(
                            title: UnfadingLocalized.Detail.moodTitle(id: id),
                            isSelected: true
                        ) {}
                        .allowsHitTesting(false)
                    }
                }
            }
        }
    }

    private var noteSection: some View {
        Text(detail?.noteBody ?? "")
            .font(UnfadingTheme.Font.subheadline())
            .foregroundStyle(UnfadingTheme.Color.textPrimary)
            .padding(UnfadingTheme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .unfadingCardBackground(fill: UnfadingTheme.Color.cream)
    }

    private var contributionsSection: some View {
        SectionBlock(title: UnfadingLocalized.Detail.contributionsLabel) {
            VStack(spacing: UnfadingTheme.Spacing.md) {
                ForEach(detail?.contributions ?? []) { contribution in
                    contributionCard(contribution)
                }
            }
        }
    }

    private func contributionCard(_ contribution: SampleMemoryContribution) -> some View {
        HStack(alignment: .top, spacing: UnfadingTheme.Spacing.md) {
            Text(contribution.authorInitial)
                .font(UnfadingTheme.Font.footnoteSemibold())
                .foregroundStyle(UnfadingTheme.Color.primary)
                .frame(width: 44, height: 44)
                .background(UnfadingTheme.Color.primarySoft, in: Circle())

            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                HStack {
                    Text(contribution.authorName)
                        .font(UnfadingTheme.Font.subheadlineSemibold())
                        .foregroundStyle(UnfadingTheme.Color.textPrimary)
                    Spacer()
                    Text(contribution.timeAgo)
                        .font(UnfadingTheme.Font.captionSemibold())
                        .foregroundStyle(UnfadingTheme.Color.textTertiary)
                }
                Text(contribution.comment)
                    .font(UnfadingTheme.Font.subheadline())
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
            }
        }
        .padding(UnfadingTheme.Spacing.md)
        .unfadingCardBackground(fill: UnfadingTheme.Color.cream, radius: UnfadingTheme.Radius.button)
        .accessibilityElement(children: .combine)
    }

    private var photoSymbols: [String] {
        let symbols = detail?.photoPlaceholders ?? []
        return symbols.isEmpty ? ["photo"] : symbols
    }

    private var photoStoragePaths: [String] {
        detail?.photoStoragePaths ?? []
    }

    private var costText: String? {
        guard let cost = detail?.costKRW else { return nil }
        return "\(UnfadingLocalized.Detail.costFormat)\(cost.formatted())"
    }

    private func move(delta: Int) {
        guard let currentIndex = SampleMemoryPin.samples.firstIndex(where: { $0.id == currentPin.id }) else {
            currentPin = SampleMemoryPin.samples.first ?? currentPin
            return
        }
        let count = SampleMemoryPin.samples.count
        guard count > 0 else { return }
        let nextIndex = (currentIndex + delta + count) % count
        currentPin = SampleMemoryPin.samples[nextIndex]
    }
}

private struct SectionBlock<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
            Text(title)
                .font(UnfadingTheme.Font.subheadlineSemibold())
                .foregroundStyle(UnfadingTheme.Color.textSecondary)
            content()
        }
    }
}

#Preview {
    NavigationStack {
        MemoryDetailView(pin: SampleMemoryPin.samples[0])
    }
}
