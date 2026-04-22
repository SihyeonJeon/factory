import SwiftUI

struct RewindMomentCard: View {
    let moment: RewindMoment

    var body: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.lg) {
            RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card + 2, style: .continuous)
                .fill(moment.gradient)
                .frame(height: 180)
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs + 2) {
                        Text(moment.dateLabel)
                            .font(UnfadingTheme.Font.captionSemibold())
                        Text(moment.title)
                            .font(UnfadingTheme.Font.title3Bold())
                    }
                    .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                    .padding(UnfadingTheme.Spacing.lg + 2)
                }

            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.sm) {
                Text(moment.location)
                    .font(.headline)
                    .foregroundStyle(UnfadingTheme.Color.textPrimary)
                Text(moment.summary)
                    .font(UnfadingTheme.Font.subheadline())
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
            }

            HStack {
                Label(moment.people, systemImage: "person.2.fill")
                Spacer()
                Label(moment.mood, systemImage: "heart.fill")
            }
            .font(UnfadingTheme.Font.footnoteSemibold())
            .foregroundStyle(UnfadingTheme.Color.textSecondary)
        }
        .padding(UnfadingTheme.Spacing.lg + 2)
        .unfadingCardBackground(
            fill: UnfadingTheme.Color.card,
            radius: UnfadingTheme.Radius.sheet
        )
    }
}
