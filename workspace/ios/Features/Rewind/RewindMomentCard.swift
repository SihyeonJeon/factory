import SwiftUI

// vibe-limit-checked: 7 six-story card stack, 8 Dynamic Type/Korean text, 14 narrow token-only styling
struct RewindMomentCard: View {
    let data: RewindData
    let story: RewindStoryKind
    var mode: GroupMode = .couple

    var body: some View {
        ZStack {
            story.gradient
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.lg) {
                Spacer(minLength: 90)
                storyContent
                Spacer(minLength: UnfadingTheme.Spacing.xl)
            }
            .padding(.horizontal, UnfadingTheme.Spacing.xl)
            .padding(.bottom, UnfadingTheme.Spacing.xl2)
            .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .unfadingSemanticGroup()
    }

    @ViewBuilder
    private var storyContent: some View {
        switch story {
        case .cover:
            cover
        case .topPlaces:
            topPlaces
        case .firstVisits:
            firstVisits
        case .photoDay:
            photoDay
        case .emotionCloud:
            emotionCloud
        case .timeTogether:
            timeTogether
        }
    }

    private var cover: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
            Label(UnfadingLocalized.Rewind.eyebrow, systemImage: "sparkles")
                .font(UnfadingTheme.Font.metaNum(11))
                .padding(.horizontal, UnfadingTheme.Spacing.sm)
                .frame(minHeight: 44)
                .background(UnfadingTheme.Color.textOnPrimary.opacity(0.22), in: Capsule())

            Text(UnfadingLocalized.Rewind.coverHeadline(for: mode))
                .font(UnfadingTheme.Font.pageTitle(40))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Text(data.periodTitle)
                .font(UnfadingTheme.Font.body(15))
                .foregroundStyle(UnfadingTheme.Color.textOnOverlay)

            storyPhoto(symbolName: "heart.fill", label: UnfadingLocalized.Rewind.coverPhotoLabel)
                .padding(.top, UnfadingTheme.Spacing.md)
        }
        .accessibilityIdentifier("rewind-card-cover")
    }

    private var topPlaces: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xl) {
            storyTitle(UnfadingLocalized.Rewind.topPlacesTitle, subtitle: UnfadingLocalized.Rewind.topPlacesSubtitle(for: mode))

            VStack(spacing: UnfadingTheme.Spacing.md) {
                ForEach(Array(data.topPlaces.enumerated()), id: \.element.id) { index, place in
                    HStack(spacing: UnfadingTheme.Spacing.md) {
                        Text("\(index + 1)")
                            .font(UnfadingTheme.Font.metaNum(18, weight: .black))
                            .frame(width: 44, height: 44)
                            .background(UnfadingTheme.Color.textOnPrimary.opacity(0.22), in: Circle())
                        Image(systemName: place.symbolName)
                            .frame(width: 44, height: 44)
                            .background(UnfadingTheme.Color.textOnPrimary.opacity(0.16), in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.segment, style: .continuous))
                        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xxs) {
                            Text(place.title)
                                .font(UnfadingTheme.Font.sectionTitle(18))
                            Text(UnfadingLocalized.Rewind.visitCount(place.visitCount))
                                .font(UnfadingTheme.Font.footnote())
                                .foregroundStyle(UnfadingTheme.Color.textOnOverlay)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: 58)
                }
            }
        }
        .accessibilityIdentifier("rewind-card-top-places")
    }

    private var firstVisits: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xl) {
            storyTitle(UnfadingLocalized.Rewind.firstVisitsTitle, subtitle: UnfadingLocalized.Rewind.firstVisitsSubtitle)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: UnfadingTheme.Spacing.sm), count: 3), spacing: UnfadingTheme.Spacing.sm) {
                ForEach(data.firstVisitPlaces) { place in
                    VStack(spacing: UnfadingTheme.Spacing.xs) {
                        Image(systemName: place.symbolName)
                            .font(.title3)
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .background(UnfadingTheme.Color.textOnPrimary.opacity(0.20), in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous))
                        Text(place.title)
                            .font(UnfadingTheme.Font.captionSemibold())
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.82)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .accessibilityIdentifier("rewind-card-first-visits")
    }

    private var photoDay: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xl) {
            storyTitle(UnfadingLocalized.Rewind.photoDayTitle, subtitle: UnfadingLocalized.Rewind.photoDaySubtitle)

            if let day = data.photoHeavyDay {
                Text(KSTDateFormatter.fullDate.string(from: day.date))
                    .font(UnfadingTheme.Font.pageTitle(30))
                Text(UnfadingLocalized.Rewind.photoCount(day.photoCount))
                    .font(UnfadingTheme.Font.metaNum(22, weight: .black))
                    .foregroundStyle(UnfadingTheme.Color.textOnOverlay)
                storyPhoto(symbolName: day.symbolName, label: UnfadingLocalized.Rewind.photoDayTitle)
            }
        }
        .accessibilityIdentifier("rewind-card-photo-day")
    }

    private var emotionCloud: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xl) {
            storyTitle(UnfadingLocalized.Rewind.emotionCloudTitle, subtitle: UnfadingLocalized.Rewind.emotionCloudSubtitle)

            FlowLayout(spacing: UnfadingTheme.Spacing.sm) {
                ForEach(data.emotionTags) { tag in
                    Text("#\(tag.title)")
                        .font(UnfadingTheme.Font.body(13 + CGFloat(tag.ratio * 18)))
                        .padding(.horizontal, UnfadingTheme.Spacing.md)
                        .frame(minHeight: 44)
                        .background(UnfadingTheme.Color.textOnPrimary.opacity(0.20 + tag.ratio * 0.22), in: Capsule())
                }
            }
        }
        .accessibilityIdentifier("rewind-card-emotion-cloud")
    }

    private var timeTogether: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xl) {
            storyTitle(UnfadingLocalized.Rewind.timeTogetherTitle(for: mode), subtitle: UnfadingLocalized.Rewind.timeTogetherSubtitle)

            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                Text("\(data.totalHoursTogether)")
                    .font(UnfadingTheme.Font.metaNum(86, weight: .black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(UnfadingLocalized.Rewind.hoursTogetherUnit)
                    .font(UnfadingTheme.Font.pageTitle(28))
            }

            Label(UnfadingLocalized.Rewind.timeTogetherBody(for: mode), systemImage: "person.2.fill")
                .font(UnfadingTheme.Font.body(16))
                .padding(UnfadingTheme.Spacing.md)
                .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
                .background(UnfadingTheme.Color.textOnPrimary.opacity(0.20), in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous))
        }
        .accessibilityIdentifier("rewind-card-time-together")
    }

    private func storyTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.sm) {
            Text(title)
                .font(UnfadingTheme.Font.pageTitle(32))
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(UnfadingTheme.Font.body(15))
                .foregroundStyle(UnfadingTheme.Color.textOnOverlay)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func storyPhoto(symbolName: String, label: String) -> some View {
        RoundedRectangle(cornerRadius: UnfadingTheme.Radius.sheet, style: .continuous)
            .fill(UnfadingTheme.Color.textOnPrimary.opacity(0.22))
            .aspectRatio(4.0 / 5.0, contentMode: .fit)
            .overlay {
                Image(systemName: symbolName)
                    .font(.largeTitle)
                    .foregroundStyle(UnfadingTheme.Color.textOnPrimary.opacity(0.86))
            }
            .accessibilityLabel(label)
    }
}

private extension RewindStoryKind {
    var gradient: LinearGradient {
        switch self {
        case .cover, .photoDay:
            return LinearGradient(colors: [UnfadingTheme.Color.primarySoft, UnfadingTheme.Color.primary, UnfadingTheme.Color.camel], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .topPlaces, .timeTogether:
            return LinearGradient(colors: [UnfadingTheme.Color.secondaryLight, UnfadingTheme.Color.secondary, UnfadingTheme.Color.teal], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .firstVisits, .emotionCloud:
            return LinearGradient(colors: [UnfadingTheme.Color.lavender, UnfadingTheme.Color.rose, UnfadingTheme.Color.primary], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

private struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: spacing)], alignment: .leading, spacing: spacing) {
            content()
        }
    }
}
