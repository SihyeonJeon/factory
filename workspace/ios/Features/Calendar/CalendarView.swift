import SwiftUI

// vibe-limit-checked: 8 Korean/Dynamic Type/a11y grouping, 1 screen uses reusable grid/store, 7 runtime-fidelity
struct CalendarView: View {
    @StateObject private var store = MemoryCalendarStore()
    @StateObject private var rsvpStore = RSVPStore(rsvps: [
        UUID(uuidString: "11111111-1111-4111-8111-111111111117")!: .going,
        UUID(uuidString: "22222222-2222-4222-8222-222222222227")!: .going,
        UUID(uuidString: "33333333-3333-4333-8333-333333333337")!: .going,
        UUID(uuidString: "55555555-5555-4555-8555-555555555557")!: .maybe
    ])
    @EnvironmentObject private var groupStore: GroupStore
    @EnvironmentObject private var memoryStore: MemoryStore
    @State private var planSheetDate: Date?
    @State private var isShowingMonthPicker = false
    @State private var toastMessage: String?

    private let broadcaster = NotificationBroadcaster()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: UnfadingTheme.Spacing.lg) {
                    let ym = displayedYearMonth
                    MonthlyExpenseHeader(year: ym.year, month: ym.month, total: store.monthlyExpense)

                    monthHeader
                    UnfadingMonthGrid(
                        weeks: store.weeks(),
                        selectedDate: Binding(
                            get: { store.selectedDate },
                            set: { newDate in
                                store.select(newDate)
                                if let date = newDate, store.isFutureDate(date) {
                                    planSheetDate = date
                                }
                            }
                        ),
                        hasMemory: { date in
                            hasPastMemory(on: date)
                        },
                        dayKind: { date in
                            if store.isFutureDate(date), store.hasPlan(on: date) {
                                return .plan
                            }
                            return hasPastMemory(on: date) ? .memory : .none
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

                if let toastMessage {
                    UnfadingToast(message: toastMessage)
                        .padding(.horizontal, UnfadingTheme.Spacing.lg)
                        .padding(.bottom, UnfadingTheme.Spacing.tabBarClear)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle(UnfadingLocalized.Calendar.navTitle)
            .task(id: groupStore.activeGroupId) {
                store.bind(memories: memoryStore.memories)
                if let gid = groupStore.activeGroupId {
                    await store.loadMonth(for: gid)
                }
            }
            .onAppear {
                store.bind(memories: memoryStore.memories)
            }
            .onChange(of: memoryStore.memories) { _, memories in
                store.bind(memories: memories)
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
            .sheet(isPresented: $isShowingMonthPicker) {
                MonthPickerSheet(
                    displayedMonth: store.displayedMonth,
                    onSelect: { year, month in
                        store.setDisplayedMonth(year: year, month: month)
                        isShowingMonthPicker = false
                    }
                )
                .presentationDetents([.medium, .large])
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

            Button {
                isShowingMonthPicker = true
            } label: {
                Text(store.monthTitle())
                    .font(UnfadingTheme.Font.title3Bold())
                    .foregroundStyle(UnfadingTheme.Color.textPrimary)
                    .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("calendar-month-label")
            .accessibilityLabel(UnfadingLocalized.Calendar.monthPickerTitle)
            .accessibilityHint(UnfadingLocalized.Accessibility.monthNavigationHint(monthTitle: store.monthTitle()))

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
        if let selected = store.selectedDate {
            selectedDayContent(for: selected)
        } else {
            UnfadingEmptyState(
                systemImage: "calendar.badge.clock",
                title: UnfadingLocalized.Calendar.emptyDayTitle(for: groupStore.mode),
                body: UnfadingLocalized.Calendar.emptyDayBody(for: groupStore.mode)
            )
        }
    }

    private func selectedDayContent(for date: Date) -> some View {
        let plans = plans(on: date)
        let memories = store.isFutureDate(date) ? [] : store.memoriesForSelectedDate()
        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
                dayDetailHeader(for: date)
                eventListCard(plans: plans, memories: memories)
                if groupStore.mode == .general, let event = plans.first {
                    planCard(for: event, on: date)
                        .accessibilityIdentifier("calendar-general-plan-card")
                }
                if store.isFutureDate(date) {
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
            .padding(.bottom, UnfadingTheme.Spacing.tabBarClear)
        }
    }

    private func plans(on date: Date) -> [DBEvent] {
        store.plannedEvents.filter { event in
            let day = KSTDateFormatter.truncateToDayKST(date)
            let start = KSTDateFormatter.truncateToDayKST(event.startDate)
            let end = KSTDateFormatter.truncateToDayKST(event.endDate ?? event.startDate)
            return day >= start && day <= end
        }
    }

    private func dayDetailHeader(for date: Date) -> some View {
        HStack(spacing: UnfadingTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                Text(KSTDateFormatter.fullDate.string(from: date))
                    .font(UnfadingTheme.Font.subheadlineSemibold())
                    .foregroundStyle(UnfadingTheme.Color.textPrimary)
                Label(UnfadingLocalized.Calendar.weatherSample, systemImage: "sun.max.fill")
                    .font(UnfadingTheme.Font.footnote())
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
            }
            Spacer()
        }
        .padding(UnfadingTheme.Spacing.md)
        .unfadingCardBackground(fill: UnfadingTheme.Color.sheet, radius: UnfadingTheme.Radius.button, shadow: false)
    }

    private func eventListCard(plans: [DBEvent], memories: [DBMemory]) -> some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
            Text(UnfadingLocalized.Calendar.eventsSectionTitle)
                .font(UnfadingTheme.Font.subheadlineSemibold())
                .foregroundStyle(UnfadingTheme.Color.textSecondary)
            if plans.isEmpty && memories.isEmpty {
                Text(UnfadingLocalized.Calendar.noEventsForDate)
                    .font(UnfadingTheme.Font.footnote())
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
            }
            ForEach(plans) { event in
                calendarEventRow(
                    systemImage: "calendar.badge.plus",
                    tint: UnfadingTheme.Color.lavender,
                    title: event.title,
                    subtitle: KSTDateFormatter.dateTime.string(from: event.startDate)
                )
            }
            ForEach(memories) { memory in
                NavigationLink {
                    MemoryDetailView(
                        memory: memory,
                        eventMemories: store.relatedMemories(for: memory),
                        participants: groupStore.memberProfiles,
                        mode: groupStore.mode
                    )
                } label: {
                    calendarEventRow(
                        systemImage: MemoryMapPinStyle.symbol(for: memory),
                        tint: MemoryMapPinStyle.color(for: memory),
                        title: memory.title,
                        subtitle: memory.placeTitle
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("calendar-memory-row-\(memory.id.uuidString)")
            }
        }
        .padding(UnfadingTheme.Spacing.md)
        .unfadingCardBackground(fill: UnfadingTheme.Color.sheet, radius: UnfadingTheme.Radius.button, shadow: false)
    }

    private func calendarEventRow(systemImage: String, tint: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: UnfadingTheme.Spacing.md) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(tint.opacity(0.18), in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.compact, style: .continuous))
            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                Text(title)
                    .font(UnfadingTheme.Font.subheadlineSemibold())
                    .foregroundStyle(UnfadingTheme.Color.textPrimary)
                Text(subtitle)
                    .font(UnfadingTheme.Font.footnote())
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private func planCard(for event: DBEvent, on date: Date) -> some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
            Text(UnfadingLocalized.Calendar.nextMeetingTitle(date))
                .font(UnfadingTheme.Font.title3Bold())
                .foregroundStyle(UnfadingTheme.Color.textPrimary)
            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                Label(UnfadingLocalized.Calendar.planPlaceFallback, systemImage: "mappin.and.ellipse")
                Label(KSTDateFormatter.shortTime.string(from: event.startDate), systemImage: "clock")
            }
            .font(UnfadingTheme.Font.subheadlineSemibold())
            .foregroundStyle(UnfadingTheme.Color.textPrimary)
            Text(rsvpStore.summary)
                .font(UnfadingTheme.Font.metaNum(13, weight: .bold))
                .foregroundStyle(UnfadingTheme.Color.textPrimary)
                .accessibilityIdentifier("calendar-rsvp-summary")
            HStack(spacing: UnfadingTheme.Spacing.sm) {
                Button {
                    planSheetDate = date
                } label: {
                    Text(UnfadingLocalized.Calendar.addPlanCTA)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(UnfadingPrimaryButtonStyle())
                .accessibilityIdentifier("calendar-plan-card-add")

                Button {
                    sendReminder(for: event)
                } label: {
                    Text(UnfadingLocalized.Calendar.sendReminderCTA)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("calendar-send-reminder")
            }
        }
        .padding(UnfadingTheme.Spacing.lg)
        .background(
            LinearGradient(
                colors: [UnfadingTheme.Color.secondaryLight, UnfadingTheme.Color.secondary.opacity(0.68)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous)
        )
        .accessibilityElement(children: .contain)
    }

    private func sendReminder(for event: DBEvent) {
        withAnimation(.easeInOut(duration: 0.18)) {
            toastMessage = UnfadingLocalized.Calendar.broadcastToast
        }
        Task {
            if ProcessInfo.processInfo.environment["UNFADING_UI_TEST"] != "1" {
                _ = await broadcaster.sendPlanReminder(title: event.title)
            }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.18)) {
                    toastMessage = nil
                }
            }
        }
    }

    private var displayedYearMonth: (year: Int, month: Int) {
        var cal = Calendar.current
        cal.timeZone = KSTDateFormatter.timeZone
        let comps = cal.dateComponents([.year, .month], from: store.displayedMonth)
        return (comps.year ?? 1970, comps.month ?? 1)
    }

    private func hasPastMemory(on date: Date) -> Bool {
        if store.isFutureDate(date) { return false }
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "ko_KR")
        calendar.timeZone = KSTDateFormatter.timeZone
        return store.hasMemory(on: calendar.dateComponents([.year, .month, .day], from: date))
    }
}

private struct MonthPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let displayedMonth: Date
    let onSelect: (Int, Int) -> Void

    private var years: [Int] {
        let current = Calendar.current.component(.year, from: displayedMonth)
        return Array((current - 3)...(current + 3))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
                    ForEach(years, id: \.self) { year in
                        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.sm) {
                            Text("\(year)년")
                                .font(UnfadingTheme.Font.subheadlineSemibold())
                                .foregroundStyle(UnfadingTheme.Color.textSecondary)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: UnfadingTheme.Spacing.xs), count: 3), spacing: UnfadingTheme.Spacing.xs) {
                                ForEach(1...12, id: \.self) { month in
                                    monthButton(year: year, month: month)
                                }
                            }
                        }
                    }
                }
                .padding(UnfadingTheme.Spacing.lg)
            }
            .background(UnfadingTheme.Color.cream)
            .navigationTitle(UnfadingLocalized.Calendar.monthPickerTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(UnfadingLocalized.Common.cancel) { dismiss() }
                }
            }
            .accessibilityIdentifier("calendar-month-picker")
        }
    }

    private func monthButton(year: Int, month: Int) -> some View {
        let selected = isSelected(year: year, month: month)
        return Button {
            onSelect(year, month)
        } label: {
            Text("\(month)월")
                .font(UnfadingTheme.Font.subheadlineSemibold())
                .foregroundStyle(selected ? UnfadingTheme.Color.textOnPrimary : UnfadingTheme.Color.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(
                    selected ? UnfadingTheme.Color.primary : UnfadingTheme.Color.sheet,
                    in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.compact, style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("calendar-month-\(year)-\(month)")
    }

    private func isSelected(year: Int, month: Int) -> Bool {
        var cal = Calendar.current
        cal.timeZone = KSTDateFormatter.timeZone
        let comps = cal.dateComponents([.year, .month], from: displayedMonth)
        return comps.year == year && comps.month == month
    }
}

#Preview {
    CalendarView()
        .environmentObject(GroupStore.preview())
        .environmentObject(MemoryStore(memories: MemoryStore.uiTestStubMemories()))
}
