import SwiftUI
import UIKit

// vibe-limit-checked: 8 a11y/44pt, 7 Korean detail copy, 11 DBMemory event scoped carousel
struct MemoryDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let memory: DBMemory
    let eventMemories: [DBMemory]
    let participants: [DBProfile]
    let mode: GroupMode

    @State private var currentIndex: Int
    @State private var photoPageIndex: Int = 0
    @State private var extraLine: String = ""
    @State private var didSubmitExtraLine = false

    init(
        memory: DBMemory,
        eventMemories: [DBMemory],
        participants: [DBProfile],
        mode: GroupMode
    ) {
        self.memory = memory
        self.eventMemories = eventMemories
        self.participants = participants
        self.mode = mode
        _currentIndex = State(initialValue: MemoryDetailEventScope.initialIndex(memory: memory, eventMemories: eventMemories))
    }

    init(pin: SampleMemoryPin) {
        let memory = DBMemory.sample(from: pin)
        let sameEvent = SampleMemoryPin.samples
            .map(DBMemory.sample(from:))
            .filter { $0.eventId == memory.eventId }
        self.init(
            memory: memory,
            eventMemories: sameEvent.isEmpty ? [memory] : sameEvent,
            participants: DBProfile.sampleParticipants,
            mode: .general
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xl2) {
                carousel
                metaStrip
                noteBlock
                tagChips
                similarPlacesSection
                eventMemoriesSection
                if MemoryDetailEventScope.showsParticipantsSection(mode: mode) {
                    participantsSection
                }
                expenseWeatherSection
                addOneLineSection
            }
            .padding(.horizontal, UnfadingTheme.Spacing.lg)
            .padding(.bottom, UnfadingTheme.Spacing.tabBarClear)
        }
        .background(UnfadingTheme.Color.sheet.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(UnfadingLocalized.Detail.backButton)
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(UnfadingLocalized.Detail.shareButton)

                Button {
                } label: {
                    Image(systemName: "bookmark")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(UnfadingLocalized.Detail.bookmarkButton)
            }
        }
        .accessibilityIdentifier("memory-detail-screen")
    }

    private var carousel: some View {
        VStack(spacing: UnfadingTheme.Spacing.md) {
            if currentMemory.detailPhotoPaths.count > 1 {
                TabView(selection: $photoPageIndex) {
                    ForEach(Array(currentMemory.detailPhotoPaths.enumerated()), id: \.offset) { index, path in
                        heroPhoto(photoPath: path, memory: currentMemory)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: min(UIScreen.main.bounds.width * 4 / 3, 520))
                .clipShape(RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous))

                pageIndicator
            } else {
                heroPhoto(photoPath: currentMemory.detailPhotoPaths.first, memory: currentMemory)
                    .frame(height: min(UIScreen.main.bounds.width * 4 / 3, 520))
                    .clipShape(RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous))
            }
        }
        .onChange(of: currentMemory.id) { _, _ in
            photoPageIndex = 0
        }
        .padding(.top, UnfadingTheme.Spacing.sm)
        .accessibilityIdentifier("memory-detail-carousel")
    }

    private var pageIndicator: some View {
        HStack(spacing: UnfadingTheme.Spacing.xs) {
            ForEach(Array(currentMemory.detailPhotoPaths.indices), id: \.self) { index in
                Capsule()
                    .fill(index == photoPageIndex ? UnfadingTheme.Color.primary : UnfadingTheme.Color.divider)
                    .frame(width: index == photoPageIndex ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.18), value: photoPageIndex)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 44)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("사진 \(photoPageIndex + 1) / \(currentMemory.detailPhotoPaths.count)")
    }

    private var metaStrip: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
            Text(currentMemory.title)
                .font(UnfadingTheme.Font.pageTitle(26))
                .foregroundStyle(UnfadingTheme.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: UnfadingTheme.Spacing.sm)], alignment: .leading, spacing: UnfadingTheme.Spacing.sm) {
                metaItem(systemImage: "calendar", text: KSTDateFormatter.dateTime.string(from: currentMemory.date))
                metaItem(systemImage: "sun.max", text: weatherText)
                metaItem(systemImage: "mappin.and.ellipse", text: currentMemory.placeTitle)
                HStack(spacing: UnfadingTheme.Spacing.xs) {
                    avatarInitial(authorName)
                    Text(authorName)
                        .font(UnfadingTheme.Font.footnote())
                        .foregroundStyle(UnfadingTheme.Color.textSecondary)
                        .lineLimit(1)
                }
                .frame(minHeight: 44, alignment: .leading)
            }
        }
        .padding(UnfadingTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .unfadingCardBackground(fill: UnfadingTheme.Color.card)
        .accessibilityIdentifier("memory-detail-meta")
    }

    private var noteBlock: some View {
        Text(currentMemory.note)
            .font(UnfadingTheme.Font.body(15))
            .lineSpacing(15 * 0.55)
            .foregroundStyle(UnfadingTheme.Color.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(UnfadingTheme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .unfadingCardBackground(fill: UnfadingTheme.Color.card)
            .accessibilityIdentifier("memory-detail-note")
    }

    @ViewBuilder
    private var tagChips: some View {
        if !currentMemory.emotions.isEmpty {
            section(title: UnfadingLocalized.Detail.moodLabel, identifier: "memory-detail-tags") {
                FlowLayout(spacing: UnfadingTheme.Spacing.sm) {
                    ForEach(currentMemory.emotions, id: \.self) { emotion in
                        Text("#\(UnfadingLocalized.draftTag(id: emotion, fallback: emotion))")
                            .font(UnfadingTheme.Font.chip())
                            .foregroundStyle(UnfadingTheme.Color.textPrimary)
                            .padding(.horizontal, UnfadingTheme.Spacing.md)
                            .frame(minHeight: 44)
                            .background(
                                UnfadingTheme.Color.chipBg,
                                in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.segment, style: .continuous)
                            )
                    }
                }
            }
        }
    }

    private var similarPlacesSection: some View {
        section(title: UnfadingLocalized.Detail.similarPlacesSection, identifier: "memory-detail-similar-places") {
            VStack(spacing: UnfadingTheme.Spacing.md) {
                SimilarPlaceCard(name: "\(currentMemory.placeTitle) 근처 산책길", distanceText: "도보 7분")
                SimilarPlaceCard(name: "\(currentMemory.placeTitle) 다음 코스", distanceText: "1.2km")
            }
        }
    }

    private var eventMemoriesSection: some View {
        section(title: UnfadingLocalized.Detail.eventMemoriesSection, identifier: "memory-detail-event-memories") {
            EventMemoryMiniGallery(memories: scopedMemories, selectedMemoryId: currentMemory.id) { selected in
                guard let next = scopedMemories.firstIndex(where: { $0.id == selected.id }) else { return }
                currentIndex = next
            }
        }
    }

    private var participantsSection: some View {
        section(title: UnfadingLocalized.Detail.participantsSection, identifier: "memory-detail-participants") {
            ParticipantAvatarRow(participants: visibleParticipants)
        }
    }

    private var expenseWeatherSection: some View {
        section(title: UnfadingLocalized.Detail.expenseWeatherSection, identifier: "memory-detail-expense-weather") {
            VStack(spacing: UnfadingTheme.Spacing.md) {
                if let costText {
                    infoRow(systemImage: "wonsign.circle", title: UnfadingLocalized.Detail.expenseSection, value: costText)
                }
                infoRow(systemImage: "cloud.sun", title: UnfadingLocalized.Detail.weatherSection, value: weatherDetailText)
            }
        }
    }

    private var addOneLineSection: some View {
        section(title: UnfadingLocalized.Detail.addOneLineCta, identifier: "memory-detail-add-one-line") {
            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
                if didSubmitExtraLine {
                    Text(extraLine)
                        .font(UnfadingTheme.Font.body())
                        .foregroundStyle(UnfadingTheme.Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(UnfadingTheme.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            UnfadingTheme.Color.accentSoft,
                            in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.button, style: .continuous)
                        )
                }

                HStack(alignment: .center, spacing: UnfadingTheme.Spacing.sm) {
                    TextField(UnfadingLocalized.Detail.addOneLinePlaceholder, text: $extraLine, axis: .vertical)
                        .font(UnfadingTheme.Font.body())
                        .foregroundStyle(UnfadingTheme.Color.textPrimary)
                        .lineLimit(1...3)
                        .disabled(didSubmitExtraLine)
                        .padding(.horizontal, UnfadingTheme.Spacing.md)
                        .frame(minHeight: 44)
                        .background(
                            UnfadingTheme.Color.surface,
                            in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.button, style: .continuous)
                        )
                        .accessibilityIdentifier("memory-detail-extra-line-field")

                    Button(UnfadingLocalized.Detail.addOneLineSave) {
                        submitExtraLine()
                    }
                    .buttonStyle(.unfadingPrimary)
                    .disabled(didSubmitExtraLine || extraLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(didSubmitExtraLine ? 0.55 : 1)
                    .accessibilityIdentifier("memory-detail-extra-line-save")
                }
            }
        }
    }

    private func heroPhoto(photoPath: String?, memory: DBMemory) -> some View {
        ZStack(alignment: .bottomLeading) {
            if let photoPath {
                RemoteImageView(storagePath: photoPath)
                    .accessibilityHidden(true)
            } else {
                Rectangle()
                    .fill(UnfadingTheme.Color.accentSoft)
                    .overlay {
                        Image(systemName: "photo")
                            .imageScale(.large)
                            .foregroundStyle(UnfadingTheme.Color.primary)
                    }
                    .accessibilityHidden(true)
            }

            LinearGradient(
                colors: [UnfadingTheme.Color.textOnPrimary.opacity(0), UnfadingTheme.Color.textPrimary.opacity(0.34)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                Text(memory.placeTitle)
                    .font(UnfadingTheme.Font.sectionTitle(18))
                    .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                Text(KSTDateFormatter.shortTime.string(from: memory.date))
                    .font(UnfadingTheme.Font.metaNum(12))
                    .foregroundStyle(UnfadingTheme.Color.textOnPrimary.opacity(0.88))
            }
            .padding(UnfadingTheme.Spacing.lg)
        }
    }

    private func metaItem(systemImage: String, text: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(UnfadingTheme.Font.footnote())
            .foregroundStyle(UnfadingTheme.Color.textSecondary)
            .frame(minHeight: 44, alignment: .leading)
            .lineLimit(2)
    }

    private func infoRow(systemImage: String, title: String, value: String) -> some View {
        HStack(spacing: UnfadingTheme.Spacing.md) {
            Image(systemName: systemImage)
                .foregroundStyle(UnfadingTheme.Color.primary)
                .frame(width: 44, height: 44)
                .background(UnfadingTheme.Color.accentSoft, in: Circle())

            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xxs) {
                Text(title)
                    .font(UnfadingTheme.Font.footnote())
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
                Text(value)
                    .font(UnfadingTheme.Font.sectionTitle())
                    .foregroundStyle(UnfadingTheme.Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(UnfadingTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .unfadingCardBackground(fill: UnfadingTheme.Color.card, radius: UnfadingTheme.Radius.button)
    }

    private func avatarInitial(_ name: String) -> some View {
        Text(String(name.prefix(1)))
            .font(UnfadingTheme.Font.footnoteSemibold())
            .foregroundStyle(UnfadingTheme.Color.primary)
            .frame(width: 32, height: 32)
            .background(UnfadingTheme.Color.accentSoft, in: Circle())
    }

    private func section<Content: View>(
        title: String,
        identifier: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
            Text(title)
                .font(UnfadingTheme.Font.sectionTitle())
                .foregroundStyle(UnfadingTheme.Color.textPrimary)
            content()
        }
        .accessibilityIdentifier(identifier)
    }

    private var scopedMemories: [DBMemory] {
        MemoryDetailEventScope.scopedMemories(memory: memory, eventMemories: eventMemories)
    }

    private var currentMemory: DBMemory {
        let memories = scopedMemories
        guard memories.indices.contains(currentIndex) else { return memories.first ?? memory }
        return memories[currentIndex]
    }

    private var visibleParticipants: [DBProfile] {
        let ids = currentMemory.participantUserIds
        guard !ids.isEmpty else { return participants }
        let filtered = participants.filter { ids.contains($0.id) }
        return filtered.isEmpty ? participants : filtered
    }

    private var authorName: String {
        participants.first(where: { $0.id == currentMemory.userId })?.displayName ?? "작성자"
    }

    private var costText: String? {
        guard let cost = currentMemory.cost else { return nil }
        return "\(UnfadingLocalized.Detail.costFormat) \(cost.formatted())"
    }

    private var weatherText: String { "맑음" }
    private var weatherDetailText: String { "맑음 · 바람 약함 · 산책하기 좋은 날" }

    private func submitExtraLine() {
        let trimmed = extraLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard MemoryDetailExtraLinePolicy.canSubmit(line: trimmed, didSubmit: didSubmitExtraLine) else { return }
        extraLine = trimmed
        didSubmitExtraLine = true
    }
}

enum MemoryDetailEventScope {
    static func scopedMemories(memory: DBMemory, eventMemories: [DBMemory]) -> [DBMemory] {
        let candidates = eventMemories.isEmpty ? [memory] : eventMemories
        let scoped: [DBMemory]
        if let eventId = memory.eventId {
            scoped = candidates.filter { $0.eventId == eventId }
        } else {
            scoped = candidates.filter { $0.id == memory.id }
        }

        if scoped.contains(where: { $0.id == memory.id }) {
            return scoped
        }
        return [memory] + scoped
    }

    static func initialIndex(memory: DBMemory, eventMemories: [DBMemory]) -> Int {
        scopedMemories(memory: memory, eventMemories: eventMemories).firstIndex { $0.id == memory.id } ?? 0
    }

    static func boundedIndex(current: Int, delta: Int, count: Int) -> Int {
        min(max(current + delta, 0), max(count - 1, 0))
    }

    static func showsParticipantsSection(mode: GroupMode) -> Bool {
        mode == .general
    }
}

enum MemoryDetailExtraLinePolicy {
    static func canSubmit(line: String, didSubmit: Bool) -> Bool {
        !didSubmit && !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private extension DBMemory {
    var detailPhotoPaths: [String] {
        let paths = photoURLs + [photoURL].compactMap { $0 }
        return paths.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    static func sample(from pin: SampleMemoryPin) -> DBMemory {
        let participants = DBProfile.sampleParticipants
        let author = participants.first?.id ?? UUID(uuidString: "00000000-0000-0000-0000-000000000017")!

        return DBMemory(
            id: pin.id,
            userId: author,
            groupId: UUID(uuidString: "11111111-1111-4111-8111-111111111117")!,
            eventId: UUID(uuidString: "99999999-9999-4999-8999-999999999991")!,
            title: UnfadingLocalized.Detail.title(for: pin),
            note: pin.detail()?.noteBody ?? pin.shortLabel,
            placeTitle: UnfadingLocalized.Detail.place(for: pin),
            address: UnfadingLocalized.Detail.place(for: pin),
            locationLat: pin.coordinate.latitude,
            locationLng: pin.coordinate.longitude,
            date: Date(timeIntervalSince1970: 1_776_000_000),
            capturedAt: nil,
            photoURL: nil,
            photoURLs: [],
            categories: [],
            emotions: pin.detail()?.moodTagIDs ?? [],
            participantUserIds: participants.map(\.id),
            cost: pin.detail()?.costKRW,
            reactionCount: 0,
            createdAt: nil
        )
    }
}

private extension DBProfile {
    static let sampleParticipants: [DBProfile] = [
        DBProfile(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000017")!,
            email: "sample1@unfading.app",
            displayName: "시현",
            photoURL: nil,
            createdAt: Date(timeIntervalSince1970: 1_776_000_000)
        ),
        DBProfile(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000018")!,
            email: "sample2@unfading.app",
            displayName: "민지",
            photoURL: nil,
            createdAt: Date(timeIntervalSince1970: 1_776_000_000)
        ),
        DBProfile(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000019")!,
            email: "sample3@unfading.app",
            displayName: "준호",
            photoURL: nil,
            createdAt: Date(timeIntervalSince1970: 1_776_000_000)
        )
    ]
}

private struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: spacing)], alignment: .leading, spacing: spacing) {
            content()
        }
    }
}

#Preview {
    NavigationStack {
        MemoryDetailView(pin: SampleMemoryPin.samples[0])
    }
}
