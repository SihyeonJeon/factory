import SwiftUI
import UserNotifications

/// F2-cal / F11: 미래 날짜에 "계획"(event) 추가. 여행 토글 on 시 여러 날, 알람 토글 on 시 UNUserNotification 스케줄.
struct EventPlanSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var groupStore: GroupStore

    let initialDate: Date
    let onCreated: (DBEvent) -> Void

    @State private var title: String = ""
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var isTrip = false
    @State private var wantsReminder = false
    @State private var reminderAt: Date
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var reminderPermissionDenied = false

    private let repo: EventRepository

    init(
        initialDate: Date,
        repo: EventRepository = SupabaseEventRepository(),
        onCreated: @escaping (DBEvent) -> Void
    ) {
        self.initialDate = initialDate
        self.repo = repo
        self.onCreated = onCreated
        _startDate = State(initialValue: initialDate)
        _endDate = State(initialValue: initialDate)
        _reminderAt = State(initialValue: initialDate.addingTimeInterval(-60 * 60))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(UnfadingLocalized.Calendar.planTitlePlaceholder, text: $title)
                        .accessibilityIdentifier("plan-title-field")
                }

                Section {
                    DatePicker("시작", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                        .environment(\.locale, Locale(identifier: "ko_KR"))
                        .accessibilityIdentifier("plan-start-date")
                    Toggle(UnfadingLocalized.Calendar.multiDayToggle, isOn: $isTrip)
                        .accessibilityIdentifier("plan-trip-toggle")
                    if isTrip {
                        DatePicker("종료", selection: $endDate, in: startDate..., displayedComponents: [.date, .hourAndMinute])
                            .environment(\.locale, Locale(identifier: "ko_KR"))
                            .accessibilityIdentifier("plan-end-date")
                    }
                }

                Section {
                    Toggle(UnfadingLocalized.Calendar.reminderToggle, isOn: $wantsReminder)
                        .accessibilityIdentifier("plan-reminder-toggle")
                    if wantsReminder {
                        DatePicker(
                            UnfadingLocalized.Calendar.reminderTimeLabel,
                            selection: $reminderAt,
                            in: ...startDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .environment(\.locale, Locale(identifier: "ko_KR"))
                        .accessibilityIdentifier("plan-reminder-time")
                    }
                    if reminderPermissionDenied {
                        Text(UnfadingLocalized.Calendar.reminderPermissionDenied)
                            .font(UnfadingTheme.Font.footnote())
                            .foregroundStyle(UnfadingTheme.Color.textSecondary)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(UnfadingTheme.Font.footnote())
                            .foregroundStyle(UnfadingTheme.Color.textSecondary)
                    }
                }
            }
            .navigationTitle(UnfadingLocalized.Calendar.planSheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(UnfadingLocalized.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(UnfadingLocalized.Calendar.addPlanCTA) {
                        Task { await submit() }
                    }
                    .disabled(!canSubmit)
                    .accessibilityIdentifier("plan-submit")
                }
            }
        }
    }

    private var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isSubmitting
    }

    private func submit() async {
        guard let groupId = groupStore.activeGroupId else {
            errorMessage = "그룹을 먼저 선택해주세요."
            return
        }
        isSubmitting = true
        defer { isSubmitting = false }
        errorMessage = nil
        do {
            let event = try await repo.createEvent(
                groupId: groupId,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                startDate: startDate,
                endDate: isTrip ? endDate : nil,
                reminderAt: wantsReminder ? reminderAt : nil
            )
            if wantsReminder {
                await scheduleReminder(for: event)
            }
            onCreated(event)
            dismiss()
        } catch {
            errorMessage = String(describing: error).prefix(200).description
        }
    }

    private func scheduleReminder(for event: DBEvent) async {
        guard let fireAt = event.reminderAt else { return }
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else {
            reminderPermissionDenied = true
            return
        }
        let content = UNMutableNotificationContent()
        content.title = event.title
        content.body = UnfadingLocalized.Calendar.savedPlan
        content.sound = .default

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = KSTDateFormatter.timeZone
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fireAt)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(
            identifier: "event_plan_\(event.id.uuidString)",
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }
}
