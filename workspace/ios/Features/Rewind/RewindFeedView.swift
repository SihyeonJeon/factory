import SwiftUI

// vibe-limit-checked: 7 full-screen stories, 8 Korean labels/44pt controls, 12 reduce-motion auto-advance guard
struct RewindFeedView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var groupStore: GroupStore
    @State private var selectedIndex = 0

    private let data: RewindData
    private let onClose: () -> Void
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    private let stories = RewindStoryKind.allCases

    init(
        data: RewindData = RewindData.sample(for: DateInterval.monthContaining(Date())),
        onClose: @escaping () -> Void = {}
    ) {
        self.data = data
        self.onClose = onClose
    }

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedIndex) {
                ForEach(Array(stories.enumerated()), id: \.element.id) { index, story in
                    RewindMomentCard(data: data, story: story, mode: groupStore.mode)
                        .tag(index)
                        .overlay {
                            storyTapZones
                        }
                        .accessibilityIdentifier("rewind-story-page-\(index)")
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            .accessibilityIdentifier("rewind-stories-screen")
            .onReceive(timer) { _ in
                guard reduceMotion == false else { return }
                advance()
            }

            topChrome
        }
        .background(UnfadingTheme.Color.primary)
    }

    private var topChrome: some View {
        VStack(spacing: UnfadingTheme.Spacing.sm) {
            HStack(spacing: UnfadingTheme.Spacing.xs) {
                ForEach(0..<stories.count, id: \.self) { index in
                    Capsule()
                        .fill(index <= selectedIndex ? UnfadingTheme.Color.textOnPrimary : UnfadingTheme.Color.textOnPrimary.opacity(0.35))
                        .frame(height: 4)
                        .accessibilityLabel(UnfadingLocalized.Rewind.progressLabel(index + 1, total: stories.count))
                        .accessibilityIdentifier("rewind-progress-\(index)")
                }
            }
            .padding(.horizontal, UnfadingTheme.Spacing.md)

            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                        .frame(width: 44, height: 44)
                        .background(UnfadingTheme.Color.textOnPrimary.opacity(0.22), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(UnfadingLocalized.Rewind.closeLabel)
                .accessibilityHint(UnfadingLocalized.Rewind.closeHint)
                .accessibilityIdentifier("rewind-close")

                Spacer()

                Button {} label: {
                    Text(UnfadingLocalized.Rewind.shareLabel)
                        .font(UnfadingTheme.Font.chip(13))
                        .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                        .padding(.horizontal, UnfadingTheme.Spacing.md)
                        .frame(minHeight: 44)
                        .background(UnfadingTheme.Color.textOnPrimary.opacity(0.22), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityHint(UnfadingLocalized.Accessibility.shareRewindHint)
            }
            .padding(.horizontal, UnfadingTheme.Spacing.md)
        }
        .padding(.top, UnfadingTheme.Spacing.xs)
    }

    private var storyTapZones: some View {
        HStack(spacing: 0) {
            Button(action: rewind) {
                Color.clear
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(UnfadingLocalized.Rewind.previousStoryLabel)
            .accessibilityIdentifier("rewind-previous-zone")

            Button(action: advance) {
                Color.clear
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(UnfadingLocalized.Rewind.nextStoryLabel)
            .accessibilityIdentifier("rewind-next-zone")
        }
        .padding(.top, 96)
    }

    private func advance() {
        withAnimation(.easeInOut(duration: reduceMotion ? 0 : 0.22)) {
            selectedIndex = min(selectedIndex + 1, stories.count - 1)
        }
    }

    private func rewind() {
        withAnimation(.easeInOut(duration: reduceMotion ? 0 : 0.22)) {
            selectedIndex = max(selectedIndex - 1, 0)
        }
    }
}

private extension DateInterval {
    static func monthContaining(_ date: Date, calendar: Calendar = .current) -> DateInterval {
        let interval = calendar.dateInterval(of: .month, for: date)
        return interval ?? DateInterval(start: date, duration: 60 * 60 * 24 * 30)
    }
}

#Preview {
    RewindFeedView()
        .environmentObject(GroupStore.preview())
}
