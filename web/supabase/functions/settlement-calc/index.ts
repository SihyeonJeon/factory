/**
 * settlement-calc Edge Function
 *
 * Calculates 1/N settlement for an event and generates
 * Toss/KakaoPay deep links for each attending participant.
 *
 * Endpoints:
 *   POST /settlement-calc
 *     - create: { action: "create", event_id, total_amount }
 *       Creates settlement with 1/N split across attending guests.
 *     - mark_paid: { action: "mark_paid", event_id, user_id }
 *       Host marks a participant as paid.
 *     - get: { action: "get", event_id }
 *       Returns settlement with deep links for the requesting user.
 *
 * Required env:
 *   - SUPABASE_URL
 *   - SUPABASE_SERVICE_ROLE_KEY
 *   - SITE_URL (optional, defaults to https://moment.app)
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.103.0";

interface ParticipantStatus {
  user_id: string;
  display_name: string;
  paid: boolean;
}

interface SettlementResponse {
  settlement: {
    id: string;
    event_id: string;
    total_amount: number;
    per_person: number;
    participant_statuses: ParticipantStatus[];
    created_at: string;
  };
  deep_links?: {
    toss: string;
    kakaopay: string;
  };
}

/**
 * Build Toss송금 deep link.
 * Scheme: supertoss://send?amount=N&bank=&accountNo=&message=
 * Web fallback: https://toss.me/{username}/{amount}
 *
 * Since we don't have the host's Toss ID, we use the generic
 * amount-prefilled link that the guest can complete.
 */
function buildTossLink(amount: number, eventTitle: string): string {
  const message = encodeURIComponent(`${eventTitle} 정산`);
  // toss.me generic link — guest taps and enters recipient
  return `supertoss://send?amount=${amount}&msg=${message}`;
}

/**
 * Build KakaoPay송금 deep link.
 * Scheme: kakaotalk://kakaopay/money/to/send?amount=N
 */
function buildKakaoPayLink(amount: number): string {
  return `kakaotalk://kakaopay/money/to/send?amount=${amount}`;
}

function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function errorResponse(message: string, status = 400): Response {
  return jsonResponse({ error: message }, status);
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return errorResponse("Method not allowed", 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient(supabaseUrl, serviceRoleKey);

  // Verify the caller's JWT to get their user_id
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return errorResponse("Missing authorization", 401);
  }

  const token = authHeader.replace("Bearer ", "");
  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser(token);

  if (authError || !user) {
    return errorResponse("Invalid token", 401);
  }

  let body: {
    action: string;
    event_id?: string;
    total_amount?: number;
    user_id?: string;
  };

  try {
    body = await req.json();
  } catch {
    return errorResponse("Invalid JSON body");
  }

  const { action, event_id } = body;

  if (!event_id) {
    return errorResponse("event_id is required");
  }

  // ─── action: create ────────────────────────────────────────
  if (action === "create") {
    const { total_amount } = body;

    if (!total_amount || total_amount <= 0) {
      return errorResponse("total_amount must be a positive integer");
    }

    // Verify caller is the host
    const { data: event, error: eventError } = await supabase
      .from("events")
      .select("id, host_id, title")
      .eq("id", event_id)
      .single();

    if (eventError || !event) {
      return errorResponse("Event not found", 404);
    }

    if (event.host_id !== user.id) {
      return errorResponse("Only the host can create a settlement", 403);
    }

    // Get attending guests
    const { data: guests, error: guestsError } = await supabase
      .from("guest_states")
      .select("user_id, profiles!inner(display_name)")
      .eq("event_id", event_id)
      .eq("status", "attending");

    if (guestsError) {
      return errorResponse(`Failed to fetch guests: ${guestsError.message}`, 500);
    }

    // Include host + attending guests in the split
    const { data: hostProfile } = await supabase
      .from("profiles")
      .select("display_name")
      .eq("id", user.id)
      .single();

    const participants: ParticipantStatus[] = [
      {
        user_id: user.id,
        display_name: hostProfile?.display_name ?? "호스트",
        paid: true, // Host is considered paid (they paid the bill)
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

    const headCount = participants.length;
    const perPerson = Math.ceil(total_amount / headCount);

    // Upsert settlement (one per event)
    const { data: settlement, error: upsertError } = await supabase
      .from("settlements")
      .upsert(
        {
          event_id,
          total_amount,
          per_person: perPerson,
          participant_statuses: participants as unknown as Record<string, unknown>[],
        },
        { onConflict: "event_id" },
      )
      .select()
      .single();

    if (upsertError) {
      return errorResponse(`Failed to create settlement: ${upsertError.message}`, 500);
    }

    const response: SettlementResponse = {
      settlement: {
        ...settlement,
        participant_statuses: participants,
      },
    };

    return jsonResponse(response, 201);
  }

  // ─── action: mark_paid ─────────────────────────────────────
  if (action === "mark_paid") {
    const targetUserId = body.user_id;

    if (!targetUserId) {
      return errorResponse("user_id is required for mark_paid");
    }

    // Verify caller is the host
    const { data: event } = await supabase
      .from("events")
      .select("host_id")
      .eq("id", event_id)
      .single();

    if (!event || event.host_id !== user.id) {
      return errorResponse("Only the host can mark payments", 403);
    }

    // Get current settlement
    const { data: settlement, error: settleError } = await supabase
      .from("settlements")
      .select("*")
      .eq("event_id", event_id)
      .single();

    if (settleError || !settlement) {
      return errorResponse("Settlement not found", 404);
    }

    const statuses = settlement.participant_statuses as unknown as ParticipantStatus[];
    const updated = statuses.map((p) =>
      p.user_id === targetUserId ? { ...p, paid: true } : p,
    );

    // Check the target user actually exists in the settlement
    const targetExists = statuses.some((p) => p.user_id === targetUserId);
    if (!targetExists) {
      return errorResponse("User not found in this settlement", 404);
    }

    const { error: updateError } = await supabase
      .from("settlements")
      .update({
        participant_statuses: updated as unknown as Record<string, unknown>[],
      })
      .eq("event_id", event_id);

    if (updateError) {
      return errorResponse(`Failed to update: ${updateError.message}`, 500);
    }

    return jsonResponse({ success: true, participant_statuses: updated });
  }

  // ─── action: get ───────────────────────────────────────────
  if (action === "get") {
    // Get settlement
    const { data: settlement, error: settleError } = await supabase
      .from("settlements")
      .select("*")
      .eq("event_id", event_id)
      .single();

    if (settleError || !settlement) {
      return errorResponse("Settlement not found", 404);
    }

    // Get event title for deep link message
    const { data: event } = await supabase
      .from("events")
      .select("title")
      .eq("id", event_id)
      .single();

    const statuses = settlement.participant_statuses as unknown as ParticipantStatus[];
    const callerStatus = statuses.find((p) => p.user_id === user.id);

    const response: SettlementResponse = {
      settlement: {
        ...settlement,
        participant_statuses: statuses,
      },
    };

    // Generate deep links only for unpaid participants viewing their own settlement
    if (callerStatus && !callerStatus.paid) {
      response.deep_links = {
        toss: buildTossLink(settlement.per_person, event?.title ?? "모임"),
        kakaopay: buildKakaoPayLink(settlement.per_person),
      };
    }

    return jsonResponse(response);
  }

  return errorResponse(`Unknown action: ${action}`);
});
