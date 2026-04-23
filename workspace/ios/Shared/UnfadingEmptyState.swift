import SwiftUI

// vibe-limit-checked: 7 Korean copy via localization, 8 Dynamic Type/a11y/44pt CTA, 14 reusable empty-state surface
struct UnfadingEmptyState: View {
    private let systemImage: String
    private let title: String
    private let bodyText: String
    private let ctaTitle: String?
    private let onCta: (() -> Void)?

    init(
        systemImage: String,
        title: String,
        body: String,
        ctaTitle: String? = nil,
        onCta: (() -> Void)? = nil
    ) {
        self.systemImage = systemImage
        self.title = title
        self.bodyText = body
        self.ctaTitle = ctaTitle
        self.onCta = onCta
    }

    var body: some View {
        VStack(spacing: UnfadingTheme.Spacing.md) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(UnfadingTheme.Color.primary)
                .frame(width: 56, height: 56)
                .background(
                    UnfadingTheme.Color.primarySoft,
                    in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.button, style: .continuous)
                )
                .accessibilityHidden(true)

            VStack(spacing: UnfadingTheme.Spacing.xs) {
                Text(title)
                    .font(UnfadingTheme.Font.subheadlineSemibold())
                    .foregroundStyle(UnfadingTheme.Color.textPrimary)
                    .multilineTextAlignment(.center)

                Text(bodyText)
                    .font(UnfadingTheme.Font.subheadline())
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let ctaTitle, let onCta {
                Button(ctaTitle, action: onCta)
                    .buttonStyle(.unfadingPrimary)
                    .padding(.top, UnfadingTheme.Spacing.xs)
            }
        }
        .padding(UnfadingTheme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .unfadingCardBackground(fill: UnfadingTheme.Color.sheet, shadow: false)
        .accessibilityElement(children: ctaTitle == nil ? .combine : .contain)
    }
}
