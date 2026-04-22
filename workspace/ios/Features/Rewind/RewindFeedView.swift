import SwiftUI

struct RewindFeedView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: UnfadingTheme.Spacing.lg) {
                    ForEach(RewindMoment.samples) { moment in
                        RewindMomentCard(moment: moment)
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
