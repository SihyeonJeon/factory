import { NextResponse } from "next/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import type { ParticipantStatus } from "@/lib/database.types";

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const MAX_TOTAL_AMOUNT = 100_000_000; // 1억원

export async function POST(request: Request) {
  const supabase = await createServerSupabaseClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json();
  const { action, eventId } = body as {
    action: string;
    eventId: string;
    totalAmount?: number;
    userId?: string;
  };

  if (!eventId) {
    return NextResponse.json(
      { error: "eventId is required" },
      { status: 400 },
    );
  }

  // Validate eventId is a proper UUID
  if (!UUID_RE.test(eventId)) {
    return NextResponse.json(
      { error: "잘못된 이벤트 ID입니다" },
      { status: 400 },
    );
  }

  // ── action: create ──
  if (action === "create") {
    const { totalAmount } = body;

    if (!totalAmount || totalAmount <= 0 || totalAmount > MAX_TOTAL_AMOUNT) {
      return NextResponse.json(
        { error: `유효한 금액을 입력해주세요 (최대 ${MAX_TOTAL_AMOUNT.toLocaleString()}원)` },
        { status: 400 },
      );
    }

    // Verify caller is host
    const { data: event } = await supabase
      .from("events")
      .select("id, host_id, title")
      .eq("id", eventId)
      .single();

    if (!event) {
      return NextResponse.json({ error: "이벤트를 찾을 수 없습니다" }, { status: 404 });
    }

    if (event.host_id !== user.id) {
      return NextResponse.json({ error: "호스트만 정산을 생성할 수 있습니다" }, { status: 403 });
    }

    // Get attending guests
    const { data: guests } = await supabase
      .from("guest_states")
      .select("user_id, profiles!inner(display_name)")
      .eq("event_id", eventId)
      .eq("status", "attending");

    // Build participant list (host + guests)
    const { data: hostProfile } = await supabase
      .from("profiles")
      .select("display_name")
      .eq("id", user.id)
      .single();

    const participants: ParticipantStatus[] = [
      {
        user_id: user.id,
        display_name: hostProfile?.display_name ?? "호스트",
        paid: true,
      },
    ];

    for (const g of guests ?? []) {
      const profile = g.profiles as unknown as { display_name: string };
      participants.push({
        user_id: g.user_id,
        display_name: profile?.display_name ?? "",
        paid: false,
      });
    }

    const perPerson = Math.ceil(totalAmount / participants.length);

    const { data: settlement, error: upsertError } = await supabase
      .from("settlements")
      .upsert(
        {
          event_id: eventId,
          total_amount: totalAmount,
          per_person: perPerson,
          participant_statuses: participants,
        },
        { onConflict: "event_id" },
      )
      .select()
      .single();

    if (upsertError) {
      console.error("Settlement create error:", upsertError);
      return NextResponse.json(
        { error: "정산 생성에 실패했습니다" },
        { status: 500 },
      );
    }

    return NextResponse.json({
      settlement: { ...settlement, participant_statuses: participants },
    });
  }

  // ── action: mark_paid ──
  if (action === "mark_paid") {
    const targetUserId = body.userId;

    if (!targetUserId) {
      return NextResponse.json(
        { error: "userId is required" },
        { status: 400 },
      );
    }

    // Validate userId is a proper UUID
    if (!UUID_RE.test(targetUserId)) {
      return NextResponse.json(
        { error: "잘못된 사용자 ID입니다" },
        { status: 400 },
      );
    }

    // Verify caller is host
    const { data: event } = await supabase
      .from("events")
      .select("host_id")
      .eq("id", eventId)
      .single();

    if (!event || event.host_id !== user.id) {
      return NextResponse.json(
        { error: "호스트만 정산 상태를 변경할 수 있습니다" },
        { status: 403 },
      );
    }

    // Atomic mark_paid via Postgres RPC (row-level lock prevents race conditions)
    const { data: updatedStatuses, error: rpcError } = await supabase.rpc(
      "mark_participant_paid",
      { p_event_id: eventId, p_user_id: targetUserId },
    );

    if (rpcError) {
      console.error("Settlement mark_paid error:", rpcError);
      if (rpcError.message?.includes("settlement_not_found")) {
        return NextResponse.json({ error: "정산을 찾을 수 없습니다" }, { status: 404 });
      }
      return NextResponse.json(
        { error: "상태 변경에 실패했습니다" },
        { status: 500 },
      );
    }

    return NextResponse.json({ participant_statuses: updatedStatuses });
  }

  return NextResponse.json({ error: "알 수 없는 action입니다" }, { status: 400 });
}
