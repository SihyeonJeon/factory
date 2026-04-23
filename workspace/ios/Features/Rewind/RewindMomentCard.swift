import SwiftUI

// vibe-limit-checked: 8 44pt/a11y/Dynamic Type, 7 immersive runtime fidelity, 14 narrow reusable-token surface
struct RewindMomentCard: View {
    let moment: RewindMoment

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: UnfadingTheme.Radius.sheet, style: .continuous)
                .fill(moment.gradient)

            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.lg) {
                Spacer()

                VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.sm) {
                    Text(UnfadingLocalized.Rewind.dateLabel(for: moment))
                        .font(UnfadingTheme.Font.captionSemibold())
                    Text(UnfadingLocalized.Rewind.title(for: moment))
                        .font(UnfadingTheme.Font.title())
                    Text(UnfadingLocalized.Rewind.location(for: moment))
                        .font(UnfadingTheme.Font.subheadlineSemibold())
                    Text(UnfadingLocalized.Rewind.summary(for: moment))
                        .font(UnfadingTheme.Font.subheadline())
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                .accessibilityElement(children: .combine)

                HStack(spacing: UnfadingTheme.Spacing.sm) {
                    Button {
                    } label: {
                        Label(UnfadingLocalized.Rewind.shareLabel, systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(UnfadingTheme.Color.primary)
                    .accessibilityHint(UnfadingLocalized.Accessibility.shareRewindHint)

                    Button {
                    } label: {
                        Label(UnfadingLocalized.Rewind.rewatchLabel, systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityHint(UnfadingLocalized.Accessibility.rewatchRewindHint)
                }
            }
            .padding(UnfadingTheme.Spacing.xl)
        }
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
        .unfadingCardBackground(
            fill: UnfadingTheme.Color.surface,
            radius: UnfadingTheme.Radius.sheet,
            shadow: true
        )
    }
}
