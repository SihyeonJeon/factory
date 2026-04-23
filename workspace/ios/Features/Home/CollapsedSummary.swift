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
        switch mode {
        case .couple:
            return "우리의 추억 \(count) · 위로 스와이프"
        case .general:
            return "크루 기록 \(count) · 위로 스와이프"
        }
    }
}
