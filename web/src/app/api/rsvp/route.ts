import { NextResponse } from "next/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import type { RsvpStatusEnum, FeeIntentionEnum } from "@/lib/database.types";

export async function POST(request: Request) {
  const supabase = await createServerSupabaseClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json();
  const { eventId, status, companionCount, feeIntention } = body as {
    eventId: string;
    status: RsvpStatusEnum;
    companionCount: number;
    feeIntention: FeeIntentionEnum | null;
  };

  if (!eventId || !status) {
    return NextResponse.json(
      { error: "eventId and status are required" },
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
      companion_count: companionCount ?? 0,
      fee_intention: feeIntention,
    },
    { onConflict: "event_id,user_id" },
  );

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ ok: true });
}
