import SwiftUI

struct MemoryRowCardModel: Identifiable {
    let id: UUID
    let title: String
    let place: String
    let time: String
    let note: String
    let moodTags: [String]
    let photoSymbols: [String]
    let photoPath: String?
    let tint: Color
    let postCount: Int
    let likeCount: Int

    static func sampleItems(for pins: [SampleMemoryPin]) -> [MemoryRowCardModel] {
        pins.compactMap { pin in
            guard let detail = pin.detail() else { return nil }
            return MemoryRowCardModel(
                id: detail.id,
                title: UnfadingLocalized.Detail.title(for: pin),
                place: UnfadingLocalized.Detail.place(for: pin),
                time: UnfadingLocalized.Detail.time(for: pin),
                note: detail.noteBody,
                moodTags: detail.moodTagIDs.map { UnfadingLocalized.Detail.moodTitle(id: $0) },
                photoSymbols: detail.photoPlaceholders,
                photoPath: nil,
                tint: pin.color,
                postCount: max(detail.contributions.count, 1),
                likeCount: detail.moodTagIDs.count + detail.contributions.count
            )
        }
    }

    static func realItems(for memories: [DBMemory]) -> [MemoryRowCardModel] {
        memories.sorted { $0.date > $1.date }.map { memory in
            MemoryRowCardModel(
                id: memory.id,
                title: memory.title,
                place: memory.placeTitle,
                time: KSTDateFormatter.shortTime.string(from: memory.date),
                note: memory.note,
                moodTags: memory.emotions.map { UnfadingLocalized.Detail.moodTitle(id: $0) },
                photoSymbols: [MemoryMapPinStyle.symbol(for: memory), "camera.fill"],
                photoPath: memory.homePhotoPaths.first,
                tint: MemoryMapPinStyle.color(for: memory),
                postCount: max(memory.participantUserIds.count, 1),
                likeCount: memory.reactionCount
            )
        }
    }
}

struct MemoryRowCard: View {
    let item: MemoryRowCardModel

    var body: some View {
        HStack(alignment: .top, spacing: UnfadingTheme.Spacing.sm) {
            thumbnail

            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                HStack(alignment: .firstTextBaseline, spacing: UnfadingTheme.Spacing.xs) {
                    Text(item.time)
                        .font(UnfadingTheme.Font.metaNum(11, weight: .bold))
                        .foregroundStyle(UnfadingTheme.Color.textSecondary)
                        .lineLimit(1)

                    Spacer(minLength: UnfadingTheme.Spacing.xs)

                    HStack(spacing: UnfadingTheme.Spacing.xs) {
                        Label("\(item.postCount)", systemImage: "text.bubble.fill")
                        Label("\(item.likeCount)", systemImage: "heart.fill")
                    }
                    .font(UnfadingTheme.Font.metaNum(10, weight: .bold))
                    .foregroundStyle(UnfadingTheme.Color.textTertiary)
                    .labelStyle(.titleAndIcon)
                }

                Text(item.place)
                    .font(UnfadingTheme.Font.sectionTitle(14))
                    .foregroundStyle(UnfadingTheme.Color.textPrimary)
                    .lineLimit(1)

                Text(item.note)
                    .font(UnfadingTheme.Font.body(12.5))
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                moodTags
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(UnfadingTheme.Spacing.sm)
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
        .background(
            UnfadingTheme.Color.card,
            in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous)
                .stroke(UnfadingTheme.Color.divider, lineWidth: 0.5)
        }
        .shadow(style: UnfadingTheme.Shadow.card)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(UnfadingLocalized.Home.memoryRowAccessibilityLabel(
            place: item.place,
            time: item.time,
            note: item.note
        ))
    }

    private var thumbnail: some View {
        ZStack {
            if let path = item.photoPath {
                RemoteImageView(storagePath: path)
            } else {
                item.tint.opacity(0.22)

                HStack(spacing: 5) {
                    ForEach(Array(item.photoSymbols.prefix(2).enumerated()), id: \.offset) { _, symbol in
                        Image(systemName: symbol)
                            .imageScale(.medium)
                            .foregroundStyle(item.tint)
                    }
                }
            }
        }
        .frame(width: 76, height: 76)
        .clipShape(RoundedRectangle(cornerRadius: UnfadingTheme.Radius.compact, style: .continuous))
        .accessibilityHidden(true)
    }

    private var moodTags: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: UnfadingTheme.Spacing.xs) {
                ForEach(item.moodTags.prefix(3), id: \.self) { tag in
                    Text(tag)
                        .font(UnfadingTheme.Font.tag(10.5))
                        .foregroundStyle(UnfadingTheme.Color.primary)
                        .padding(.horizontal, UnfadingTheme.Spacing.sm)
                        .frame(minHeight: 26)
                        .background(UnfadingTheme.Color.accentSoft, in: Capsule())
                }
            }
        }
        .accessibilityHidden(true)
    }
}

extension DBMemory {
    var homePhotoPaths: [String] {
        (photoURLs + [photoURL].compactMap { $0 })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
