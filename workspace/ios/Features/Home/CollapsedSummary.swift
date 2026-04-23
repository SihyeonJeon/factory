import SwiftUI

struct CollapsedSummary: View {
    let mode: GroupMode
    let count: Int

    var body: some View {
        Text(copy)
            .font(UnfadingTheme.Font.body(11))
            .foregroundStyle(UnfadingTheme.Color.textSecondary)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .accessibilityHint(UnfadingLocalized.Accessibility.bottomSheetHandleHint)
            .accessibilityIdentifier("sheet-collapsed-summary")
    }

    private var copy: String {
        UnfadingLocalized.Home.collapsedMemoryTitle(for: mode, count: count)
    }
}
