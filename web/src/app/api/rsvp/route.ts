import { NextResponse } from "next/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import type { RsvpStatusEnum, FeeIntentionEnum } from "@/lib/database.types";

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const VALID_STATUSES: ReadonlySet<string> = new Set(["attending", "declined", "maybe"]);
const VALID_FEE_INTENTIONS: ReadonlySet<string> = new Set(["will_pay", "undecided"]);

export async function POST(request: Request) {
  const supabase = await createServerSupabaseClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  let body: { eventId: string; status: RsvpStatusEnum; companionCount: number; feeIntention: FeeIntentionEnum | null };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "잘못된 요청입니다" }, { status: 400 });
  }
  const { eventId, status, companionCount, feeIntention } = body;

  if (!eventId || !status) {
    return NextResponse.json(
      { error: "eventId and status are required" },
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

  // Validate status enum
  if (!VALID_STATUSES.has(status)) {
    return NextResponse.json(
      { error: "유효하지 않은 참석 상태입니다" },
      { status: 400 },
    );
  }

  // Validate and clamp companionCount (0-10, matching client UI)
  const clampedCompanionCount = Math.max(0, Math.min(10, Math.floor(Number(companionCount) || 0)));

  // Validate feeIntention if provided
  if (feeIntention !== null && feeIntention !== undefined && !VALID_FEE_INTENTIONS.has(feeIntention)) {
    return NextResponse.json(
      { error: "유효하지 않은 회비 납부 의사입니다" },
      { status: 400 },
    );
  }

  // Verify the event exists
  const { data: event } = await supabase
    .from("events")
    .select("id")
    .eq("id", eventId)
    .single();

  if (!event) {
    return NextResponse.json({ error: "Event not found" }, { status: 404 });
  }

  // Upsert guest_states (a user can change their RSVP)
  const { error } = await supabase.from("guest_states").upsert(
    {
      event_id: eventId,
      user_id: user.id,
      status,
      companion_count: clampedCompanionCount,
      fee_intention: feeIntention,
    },
    { onConflict: "event_id,user_id" },
  );

  if (error) {
    console.error("RSVP upsert error:", error);
    return NextResponse.json({ error: "응답 저장에 실패했습니다" }, { status: 500 });
  }

  return NextResponse.json({ ok: true });
}
