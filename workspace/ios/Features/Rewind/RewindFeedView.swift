import SwiftUI

// vibe-limit-checked: 7 immersive vertical story feed, 8 Dynamic Type/Korean labels, 14 narrow review surface
struct RewindFeedView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: UnfadingTheme.Spacing.lg) {
                    RewindReminderRow()

                    if RewindMoment.samples.isEmpty {
                        UnfadingEmptyState(
                            systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                            title: UnfadingLocalized.EmptyState.rewindTitle,
                            body: UnfadingLocalized.EmptyState.rewindBody
                        )
                    } else {
                        ForEach(RewindMoment.samples) { moment in
                            RewindMomentCard(moment: moment)
                        }
                    }
                }
                .padding(UnfadingTheme.Spacing.xl)
            }
            .background(UnfadingTheme.Color.cream)
            .navigationTitle(UnfadingLocalized.Rewind.navTitle)
        }
    }
}

#Preview {
    RewindFeedView()
}
