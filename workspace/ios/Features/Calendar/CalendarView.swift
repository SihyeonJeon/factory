import SwiftUI

// vibe-limit-checked: 8 Korean/Dynamic Type/a11y grouping, 1 screen uses reusable grid/store, 7 runtime-fidelity
struct CalendarView: View {
    @StateObject private var store = MemoryCalendarStore()
    @EnvironmentObject private var groupStore: GroupStore
    @State private var planSheetDate: Date?

    var body: some View {
        NavigationStack {
            VStack(spacing: UnfadingTheme.Spacing.lg) {
                let ym = {
                    var cal = Calendar.current
                    cal.timeZone = KSTDateFormatter.timeZone
                    let comps = cal.dateComponents([.year, .month], from: store.displayedMonth)
                    return (comps.year ?? 1970, comps.month ?? 1)
                }()
                MonthlyExpenseHeader(year: ym.0, month: ym.1, total: store.monthlyExpense)

                monthHeader
                UnfadingMonthGrid(
                    weeks: store.weeks(),
                    selectedDate: Binding(
                        get: { store.selectedDate },
                        set: { newDate in
                            store.select(newDate)
                            if let d = newDate, store.isFutureDate(d) {
                                planSheetDate = d
                            }
                        }
                    ),
                    hasMemory: { date in
                        // F2-cal: 미래 날짜는 "추억" 점으로 표시하지 않음
                        if store.isFutureDate(date) { return false }
                        var calendar = Calendar.current
                        calendar.locale = Locale(identifier: "ko_KR")
                        calendar.timeZone = KSTDateFormatter.timeZone
                        return store.hasMemory(on: calendar.dateComponents([.year, .month, .day], from: date))
                    }
                )
                Divider()
                dayContentList
                Spacer(minLength: 0)
            }
            .padding(.horizontal, UnfadingTheme.Spacing.lg)
            .padding(.vertical, UnfadingTheme.Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(UnfadingTheme.Color.cream)
            .navigationTitle(UnfadingLocalized.Calendar.navTitle)
            .task(id: groupStore.activeGroupId) {
                if let gid = groupStore.activeGroupId {
                    await store.loadMonth(for: gid)
                }
            }
            .task(id: store.displayedMonth) {
                if let gid = groupStore.activeGroupId {
                    await store.loadMonth(for: gid)
                }
            }
            .sheet(item: Binding(
                get: { planSheetDate.map(PlanSheetItem.init) },
                set: { planSheetDate = $0?.date }
            )) { item in
                EventPlanSheet(initialDate: item.date) { _ in
                    // 저장 후 다시 월 로드
                    if let gid = groupStore.activeGroupId {
                        Task { await store.loadMonth(for: gid) }
                    }
                }
                .environmentObject(groupStore)
            }
        }
    }

    private struct PlanSheetItem: Identifiable {
        let date: Date
        var id: Date { date }
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
    private var dayContentList: some View {
        if let selected = store.selectedDate, store.isFutureDate(selected) {
            futureDayContent(for: selected)
        } else {
            pastDayContent
        }
    }

    private func futureDayContent(for date: Date) -> some View {
        let plans = store.plannedEvents.filter { event in
            let day = KSTDateFormatter.truncateToDayKST(date)
            let start = KSTDateFormatter.truncateToDayKST(event.startDate)
            let end = KSTDateFormatter.truncateToDayKST(event.endDate ?? event.startDate)
            return day >= start && day <= end
        }
        return VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
            Text(UnfadingLocalized.Calendar.plansForDate)
                .font(UnfadingTheme.Font.subheadlineSemibold())
                .foregroundStyle(UnfadingTheme.Color.textSecondary)
            if plans.isEmpty {
                Text(UnfadingLocalized.Calendar.futureDayHint)
                    .font(UnfadingTheme.Font.footnote())
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
            } else {
                ForEach(plans) { event in
                    HStack(spacing: UnfadingTheme.Spacing.md) {
                        Image(systemName: "calendar.badge.plus")
                            .foregroundStyle(UnfadingTheme.Color.lavender)
                            .frame(width: 44, height: 44)
                            .background(UnfadingTheme.Color.lavender.opacity(0.18), in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.button, style: .continuous))
                        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                            Text(event.title)
                                .font(UnfadingTheme.Font.subheadlineSemibold())
                                .foregroundStyle(UnfadingTheme.Color.textPrimary)
                            Text(KSTDateFormatter.dateTime.string(from: event.startDate))
                                .font(UnfadingTheme.Font.footnote())
                                .foregroundStyle(UnfadingTheme.Color.textSecondary)
                        }
                    }
                    .padding(UnfadingTheme.Spacing.md)
                    .unfadingCardBackground(fill: UnfadingTheme.Color.sheet, radius: UnfadingTheme.Radius.button, shadow: false)
                }
            }
            Button {
                planSheetDate = date
            } label: {
                Label(UnfadingLocalized.Calendar.addPlanCTA, systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("calendar-add-plan")
        }
    }

    @ViewBuilder
    private var pastDayContent: some View {
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
        .environmentObject(GroupStore.preview())
}
