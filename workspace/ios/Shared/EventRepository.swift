import Foundation
import Supabase

/// F9/F11/F2-cal: 이벤트(=데이트/모임) + 월 지출 집계 Supabase RPC 게이트웨이.
protocol EventRepository: Sendable {
    func plannedEvents(groupId: UUID, startUTC: Date, endUTC: Date) async throws -> [DBEvent]
    func monthlyExpenseKST(groupId: UUID, year: Int, month: Int) async throws -> Int64
    func createEvent(
        groupId: UUID,
        title: String,
        startDate: Date,
        endDate: Date?,
        reminderAt: Date?
    ) async throws -> DBEvent
    func findEventAt(groupId: UUID, timestamp: Date) async throws -> DBEvent?
}

struct SupabaseEventRepository: EventRepository {
    private var db: PostgrestClient { SupabaseService.shared.database }

    func plannedEvents(groupId: UUID, startUTC: Date, endUTC: Date) async throws -> [DBEvent] {
        struct Params: Encodable {
            let p_group_id: UUID
            let p_start_utc: Date
            let p_end_utc: Date
        }
        return try await db.rpc(
            "planned_events_for_range_kst",
            params: Params(p_group_id: groupId, p_start_utc: startUTC, p_end_utc: endUTC)
        )
        .execute()
        .value
    }

    func monthlyExpenseKST(groupId: UUID, year: Int, month: Int) async throws -> Int64 {
        struct Params: Encodable {
            let p_group_id: UUID
            let p_year: Int
            let p_month: Int
        }
        return try await db.rpc(
            "monthly_expense_kst",
            params: Params(p_group_id: groupId, p_year: year, p_month: month)
        )
        .execute()
        .value
    }

    func createEvent(
        groupId: UUID,
        title: String,
        startDate: Date,
        endDate: Date?,
        reminderAt: Date?
    ) async throws -> DBEvent {
        struct Params: Encodable {
            let p_group_id: UUID
            let p_title: String
            let p_start_date: Date
            let p_end_date: Date?
            let p_reminder_at: Date?
        }
        return try await db.rpc(
            "create_event",
            params: Params(
                p_group_id: groupId,
                p_title: title,
                p_start_date: startDate,
                p_end_date: endDate,
                p_reminder_at: reminderAt
            )
        )
        .execute()
        .value
    }

    func findEventAt(groupId: UUID, timestamp: Date) async throws -> DBEvent? {
        struct Params: Encodable {
            let p_group_id: UUID
            let p_at: Date
        }
        let row: DBEvent? = try await db.rpc(
            "find_event_at",
            params: Params(p_group_id: groupId, p_at: timestamp)
        )
        .execute()
        .value
        return row
    }
}
