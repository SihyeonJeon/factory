import SwiftUI

// vibe-limit-checked: 8 Dynamic Type/a11y/44pt controls, 5 MainActor completion flow, 7 Korean onboarding copy, 14 reusable slide model
struct OnboardingView: View {
    private struct Slide: Identifiable {
        let id: Int
        let systemImage: String
        let title: String
        let body: String
    }

    private let onComplete: () -> Void
    @State private var selection = 0

    private let slides: [Slide] = [
        .init(
            id: 0,
            systemImage: "map.fill",
            title: UnfadingLocalized.Onboarding.slide1Title,
            body: UnfadingLocalized.Onboarding.slide1Body
        ),
        .init(
            id: 1,
            systemImage: "mappin.and.ellipse",
            title: UnfadingLocalized.Onboarding.slide2Title,
            body: UnfadingLocalized.Onboarding.slide2Body
        ),
        .init(
            id: 2,
            systemImage: "person.2.fill",
            title: UnfadingLocalized.Onboarding.slide3Title,
            body: UnfadingLocalized.Onboarding.slide3Body
        )
    ]

    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            UnfadingTheme.Color.cream
                .ignoresSafeArea()

            TabView(selection: $selection) {
                ForEach(slides) { slide in
                    slideView(slide)
                        .tag(slide.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            pageIndicator
                .padding(.bottom, UnfadingTheme.Spacing.xl)

            if selection != slides.last?.id {
                VStack {
                    HStack {
                        Spacer()
                        Button(UnfadingLocalized.Onboarding.skipCta, action: onComplete)
                            .buttonStyle(.bordered)
                            .frame(minHeight: 44)
                            .accessibilityHint(UnfadingLocalized.Accessibility.onboardingSkipHint)
                    }
                    Spacer()
                }
                .padding(UnfadingTheme.Spacing.xl)
            }
        }
    }

    private func slideView(_ slide: Slide) -> some View {
        VStack(spacing: UnfadingTheme.Spacing.xl) {
            Spacer(minLength: UnfadingTheme.Spacing.xxl)

            Image(systemName: slide.systemImage)
                .font(.largeTitle)
                .foregroundStyle(UnfadingTheme.Color.primary)
                .frame(width: 72, height: 72)
                .background(
                    UnfadingTheme.Color.primarySoft,
                    in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous)
                )
                .accessibilityHidden(true)

            VStack(spacing: UnfadingTheme.Spacing.md) {
                Text(slide.title)
                    .font(UnfadingTheme.Font.title())
                    .foregroundStyle(UnfadingTheme.Color.textPrimary)
                    .multilineTextAlignment(.center)

                Text(slide.body)
                    .font(UnfadingTheme.Font.subheadline())
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if slide.id == slides.last?.id {
                Button(UnfadingLocalized.Onboarding.startCta, action: onComplete)
                    .buttonStyle(.unfadingPrimaryFullWidth)
                    .padding(.top, UnfadingTheme.Spacing.md)
                    .accessibilityHint(UnfadingLocalized.Accessibility.onboardingStartHint)
            }

            Spacer(minLength: 96)
        }
        .padding(.horizontal, UnfadingTheme.Spacing.xl)
        .accessibilityElement(children: .contain)
    }

    private var pageIndicator: some View {
        HStack(spacing: UnfadingTheme.Spacing.sm) {
            ForEach(slides) { slide in
                Circle()
                    .fill(slide.id == selection ? UnfadingTheme.Color.primary : UnfadingTheme.Color.textTertiary)
                    .frame(width: 8, height: 8)
            }
        }
        .frame(minHeight: 44)
        .accessibilityLabel(UnfadingLocalized.Onboarding.pageIndicatorHint)
    }
}
