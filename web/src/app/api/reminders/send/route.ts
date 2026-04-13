import { NextResponse } from "next/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * POST /api/reminders/send
 * Host-triggered manual reminder for a specific event.
 * Body: { event_id: string }
 *
 * Delegates to the send-reminder Edge Function with the event_id.
 */
export async function POST(request: Request) {
  const supabase = await createServerSupabaseClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json();
  const eventId = body.event_id;

  if (typeof eventId !== "string" || !UUID_RE.test(eventId)) {
    return NextResponse.json(
      { error: "Invalid event_id" },
      { status: 400 },
    );
  }

  // Verify user is the host of this event
  const { data: event } = await supabase
    .from("events")
    .select("id, host_id")
    .eq("id", eventId)
    .single();

  if (!event) {
    return NextResponse.json({ error: "Event not found" }, { status: 404 });
  }

  if (event.host_id !== user.id) {
    return NextResponse.json(
      { error: "Only the host can send reminders" },
      { status: 403 },
    );
  }

  // Invoke the send-reminder Edge Function
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!serviceRoleKey) {
    return NextResponse.json(
      { error: "Server configuration error: missing service role key" },
      { status: 500 },
    );
  }

  const edgeFnUrl = `${supabaseUrl}/functions/v1/send-reminder`;

  const edgeResponse = await fetch(edgeFnUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${serviceRoleKey}`,
    },
    body: JSON.stringify({ event_id: eventId }),
  });

  const result = await edgeResponse.json();

  if (!edgeResponse.ok) {
    return NextResponse.json(
      { error: result.error ?? "Failed to send reminder" },
      { status: edgeResponse.status },
    );
  }

  return NextResponse.json(result);
}
