import SwiftUI

// vibe-limit-checked: 2 reusable month grid, 7 visual fidelity, 8 44pt/a11y/Dynamic Type
struct UnfadingMonthGrid: View {
    let weeks: [[MemoryCalendarStore.CalendarCell]]
    @Binding var selectedDate: Date?
    let hasMemory: (Date) -> Bool
    let dayKind: (Date) -> MemoryCalendarStore.DayKind

    private let columns = Array(repeating: GridItem(.flexible(), spacing: UnfadingTheme.Spacing.xs), count: 7)
    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "ko_KR")
        return calendar
    }

    var body: some View {
        VStack(spacing: UnfadingTheme.Spacing.sm) {
            weekdayHeader
            LazyVGrid(columns: columns, spacing: UnfadingTheme.Spacing.xs) {
                ForEach(weeks.flatMap { $0 }, id: \.self) { cell in
                    dayCell(cell)
                }
            }
        }
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: UnfadingTheme.Spacing.xs) {
            ForEach(UnfadingLocalized.Calendar.weekdayHeaders, id: \.self) { title in
                Text(title)
                    .font(UnfadingTheme.Font.captionSemibold())
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 32)
            }
        }
    }

    private func dayCell(_ cell: MemoryCalendarStore.CalendarCell) -> some View {
        let selected = selectedDate.map { calendar.isDate($0, inSameDayAs: cell.date) } ?? false
        let hasMemory = hasMemory(cell.date)
        let kind = dayKind(cell.date)
        return Button {
            selectedDate = cell.date
        } label: {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: cell.date))")
                    .font(UnfadingTheme.Font.footnoteSemibold())
                dotRow(for: kind)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(foregroundColor(for: cell, selected: selected))
            .background(
                Circle()
                    .fill(selected ? UnfadingTheme.Color.primary : .clear)
            )
            .overlay {
                Circle()
                    .stroke(cell.isToday ? UnfadingTheme.Color.primary : .clear, lineWidth: 1.5)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: cell, hasMemory: hasMemory))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    @ViewBuilder
    private func dotRow(for kind: MemoryCalendarStore.DayKind) -> some View {
        HStack(spacing: 2) {
            switch kind {
            case .memory, .both:
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(UnfadingTheme.Color.primary)
                        .frame(width: 4, height: 4)
                }
            case .plan:
                Circle()
                    .fill(UnfadingTheme.Color.lavender)
                    .frame(width: 5, height: 5)
            case .none:
                Circle()
                    .fill(.clear)
                    .frame(width: 5, height: 5)
            }
        }
        .frame(height: 6)
    }

    private func foregroundColor(for cell: MemoryCalendarStore.CalendarCell, selected: Bool) -> Color {
        if selected {
            return UnfadingTheme.Color.textOnPrimary
        }
        return cell.isCurrentMonth ? UnfadingTheme.Color.textPrimary : UnfadingTheme.Color.textTertiary
    }

    private func accessibilityLabel(for cell: MemoryCalendarStore.CalendarCell, hasMemory: Bool) -> String {
        let day = calendar.component(.day, from: cell.date)
        let suffix = hasMemory ? UnfadingLocalized.Calendar.memoryCountFormat(1) : UnfadingLocalized.Calendar.emptyDayTitle
        return "\(day)일, \(suffix)"
    }
}
