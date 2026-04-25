import SwiftUI
import WidgetKit

struct TodayMemoryWidget: Widget {
    private let kind = "TodayMemoryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayMemoryProvider()) { entry in
            TodayMemoryWidgetView(entry: entry)
                .widgetURL(entry.deepLinkURL)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
        .configurationDisplayName("오늘의 추억")
        .description("오늘 남긴 추억 한 장을 홈 화면에서 바로 확인합니다.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

private struct TodayMemoryWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: TodayMemoryEntry

    var body: some View {
        ZStack {
            artwork

            LinearGradient(
                colors: [
                    Color.clear,
                    UnfadingTheme.Color.overlayBackdrop.opacity(0.18),
                    UnfadingTheme.Color.overlayBackdrop.opacity(0.68)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            content
        }
        .clipShape(RoundedRectangle(cornerRadius: UnfadingTheme.Radius.sheet, style: .continuous))
    }

    private var artwork: some View {
        Group {
            if let coverAssetName = entry.memory.coverAssetName {
                Image(coverAssetName)
                    .resizable()
                    .scaledToFill()
            } else {
                gradientBackground(style: entry.memory.artworkStyle)
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
            Text("오늘의 추억")
                .font(UnfadingTheme.Font.tag(11))
                .foregroundStyle(UnfadingTheme.Color.textOnOverlay)

            Spacer(minLength: 0)

            switch family {
            case .systemSmall:
                smallLayout
            case .systemMedium:
                mediumLayout
            default:
                largeLayout
            }
        }
        .padding(contentPadding)
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs2) {
            Text(entry.memory.title)
                .font(UnfadingTheme.Font.sectionTitle(16))
                .foregroundStyle(UnfadingTheme.Color.textOnOverlay)
                .lineLimit(2)

            metadataLine

            Text(dateString(for: entry.memory.date))
                .font(UnfadingTheme.Font.body(12))
                .foregroundStyle(UnfadingTheme.Color.textOnOverlay.opacity(0.9))
        }
    }

    private var mediumLayout: some View {
        HStack(alignment: .bottom, spacing: UnfadingTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.sm) {
                Text(entry.memory.title)
                    .font(UnfadingTheme.Font.pageTitle(20))
                    .foregroundStyle(UnfadingTheme.Color.textOnOverlay)
                    .lineLimit(2)

                metadataLine

                Text(dateString(for: entry.memory.date))
                    .font(UnfadingTheme.Font.body(13))
                    .foregroundStyle(UnfadingTheme.Color.textOnOverlay.opacity(0.9))
            }

            Spacer(minLength: 0)
        }
    }

    private var largeLayout: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.sm) {
            Text(entry.memory.title)
                .font(UnfadingTheme.Font.pageTitle(24))
                .foregroundStyle(UnfadingTheme.Color.textOnOverlay)
                .lineLimit(2)

            metadataLine

            Text(dateString(for: entry.memory.date))
                .font(UnfadingTheme.Font.body(14))
                .foregroundStyle(UnfadingTheme.Color.textOnOverlay.opacity(0.9))

            Spacer(minLength: 0)

            Text("탭해서 추억 상세로 이동")
                .font(UnfadingTheme.Font.body(12))
                .foregroundStyle(UnfadingTheme.Color.textOnOverlay.opacity(0.82))
        }
    }

    private var metadataLine: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xxs) {
            Text(entry.memory.place)
                .font(UnfadingTheme.Font.body(family == .systemLarge ? 15 : 13))
                .foregroundStyle(UnfadingTheme.Color.textOnOverlay)
                .lineLimit(1)

            Text(entry.isPlaceholder ? "샘플 위젯 미리보기" : "홈 화면에서 바로 다시 열기")
                .font(UnfadingTheme.Font.body(11))
                .foregroundStyle(UnfadingTheme.Color.textOnOverlay.opacity(0.82))
                .lineLimit(1)
        }
    }

    private var contentPadding: CGFloat {
        switch family {
        case .systemSmall:
            return UnfadingTheme.Spacing.md
        case .systemMedium:
            return UnfadingTheme.Spacing.lg
        default:
            return UnfadingTheme.Spacing.xl
        }
    }

    private func gradientBackground(style: TodayMemorySample.ArtworkStyle) -> some View {
        let colors: [Color]
        switch style {
        case .peachBlossom:
            colors = [UnfadingTheme.Color.primary, UnfadingTheme.Color.accentSoft, UnfadingTheme.Color.lavender]
        case .mintSunrise:
            colors = [UnfadingTheme.Color.secondary, UnfadingTheme.Color.mapWater, UnfadingTheme.Color.primary]
        case .duskLavender:
            colors = [UnfadingTheme.Color.lavender, UnfadingTheme.Color.primarySoft, UnfadingTheme.Color.secondary]
        }

        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(UnfadingTheme.Color.textOnPrimary.opacity(0.18))
                    .frame(width: family == .systemSmall ? 76 : 110, height: family == .systemSmall ? 76 : 110)
                    .blur(radius: 6)
                    .offset(x: 22, y: -18)
            }
    }

    private func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .autoupdatingCurrent
        formatter.dateFormat = "M월 d일"
        return formatter.string(from: date)
    }
}
