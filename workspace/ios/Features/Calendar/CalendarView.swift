import SwiftUI

/// Stub screen for R3 `round_navigation_r1`. Replaced with a full month-grid
/// implementation in R8 `round_calendar_r1`. Exists now so the 5-tab root can
/// route here deterministically and accessibility structure is testable.
struct CalendarView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: UnfadingTheme.Spacing.lg) {
                Spacer()
                Image(systemName: "calendar")
                    .font(.largeTitle.weight(.light))
                    .imageScale(.large)
                    .foregroundStyle(UnfadingTheme.Color.primary)
                Text(UnfadingLocalized.Calendar.stubTitle)
                    .font(UnfadingTheme.Font.title3Bold())
                    .foregroundStyle(UnfadingTheme.Color.textPrimary)
                    .multilineTextAlignment(.center)
                Text(UnfadingLocalized.Calendar.stubBody)
                    .font(UnfadingTheme.Font.subheadline())
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, UnfadingTheme.Spacing.xl)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(UnfadingTheme.Color.cream)
            .navigationTitle(UnfadingLocalized.Calendar.navTitle)
        }
    }
}

#Preview {
    CalendarView()
}
