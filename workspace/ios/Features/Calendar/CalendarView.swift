import SwiftUI

// vibe-limit-checked: 8 Korean/Dynamic Type/a11y grouping, 1 screen uses reusable grid/store, 7 runtime-fidelity
struct CalendarView: View {
    @StateObject private var store = MemoryCalendarStore()

    var body: some View {
        NavigationStack {
            VStack(spacing: UnfadingTheme.Spacing.lg) {
                monthHeader
                UnfadingMonthGrid(
                    weeks: store.weeks(),
                    selectedDate: Binding(
                        get: { store.selectedDate },
                        set: { store.select($0) }
                    ),
                    hasMemory: { date in
                        var calendar = Calendar.current
                        calendar.locale = Locale(identifier: "ko_KR")
                        return store.hasMemory(on: calendar.dateComponents([.year, .month, .day], from: date))
                    }
                )
                Divider()
                dayMemoriesList
                Spacer(minLength: 0)
            }
            .padding(.horizontal, UnfadingTheme.Spacing.lg)
            .padding(.vertical, UnfadingTheme.Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(UnfadingTheme.Color.cream)
            .navigationTitle(UnfadingLocalized.Calendar.navTitle)
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                store.previousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(UnfadingLocalized.Calendar.previousMonthHint)
            .accessibilityHint(UnfadingLocalized.Accessibility.monthNavigationHint(monthTitle: store.monthTitle()))

            Spacer()

            Text(store.monthTitle())
                .font(UnfadingTheme.Font.title3Bold())
                .foregroundStyle(UnfadingTheme.Color.textPrimary)

            Spacer()

            Button {
                store.nextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(UnfadingLocalized.Calendar.nextMonthHint)
            .accessibilityHint(UnfadingLocalized.Accessibility.monthNavigationHint(monthTitle: store.monthTitle()))
        }
    }

    @ViewBuilder
    private var dayMemoriesList: some View {
        let memories = store.memoriesForSelectedDate()
        if memories.isEmpty {
            UnfadingEmptyState(
                systemImage: "calendar.badge.clock",
                title: UnfadingLocalized.Calendar.emptyDayTitle,
                body: UnfadingLocalized.Calendar.emptyDayBody
            )
        } else {
            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
                Text(UnfadingLocalized.Calendar.memoryCountFormat(memories.count))
                    .font(UnfadingTheme.Font.subheadlineSemibold())
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
                ForEach(memories) { pin in
                    HStack(spacing: UnfadingTheme.Spacing.md) {
                        Image(systemName: pin.symbol)
                            .foregroundStyle(UnfadingTheme.Color.primary)
                            .frame(width: 44, height: 44)
                            .background(UnfadingTheme.Color.primarySoft, in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.button, style: .continuous))
                        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                            Text(UnfadingLocalized.Detail.title(for: pin))
                                .font(UnfadingTheme.Font.subheadlineSemibold())
                                .foregroundStyle(UnfadingTheme.Color.textPrimary)
                            Text(UnfadingLocalized.Detail.place(for: pin))
                                .font(UnfadingTheme.Font.subheadline())
                                .foregroundStyle(UnfadingTheme.Color.textSecondary)
                        }
                    }
                    .padding(UnfadingTheme.Spacing.md)
                    .unfadingCardBackground(fill: UnfadingTheme.Color.sheet, radius: UnfadingTheme.Radius.button, shadow: false)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}

#Preview {
    CalendarView()
}
