import SwiftUI

/// F9: 캘린더 상단에 이번 달 지출 총액 (KST 기준) 표시.
struct MonthlyExpenseHeader: View {
    let year: Int
    let month: Int
    let total: Int64

    var body: some View {
        HStack(spacing: UnfadingTheme.Spacing.sm) {
            Text(UnfadingLocalized.Calendar.monthlyExpense)
                .font(UnfadingTheme.Font.footnoteSemibold())
                .foregroundStyle(UnfadingTheme.Color.textSecondary)
            Spacer(minLength: 0)
            Text(UnfadingLocalized.Calendar.expenseCurrencyFormat(total))
                .font(UnfadingTheme.Font.subheadlineSemibold())
                .foregroundStyle(UnfadingTheme.Color.textPrimary)
                .monospacedDigit()
        }
        .padding(.horizontal, UnfadingTheme.Spacing.md)
        .padding(.vertical, UnfadingTheme.Spacing.sm)
        .background(
            UnfadingTheme.Color.card,
            in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.button, style: .continuous)
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("calendar-monthly-expense-header")
    }
}

#Preview {
    MonthlyExpenseHeader(year: 2026, month: 4, total: 124_500)
        .padding()
}
