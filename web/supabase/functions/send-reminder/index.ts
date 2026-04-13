/**
 * send-reminder Edge Function
 *
 * D-1 cron: finds events happening in the next 23–25 hour window,
 * sends FCM push notifications to attending guests who have tokens,
 * and logs the reminder in the reminders table.
 *
 * Also supports manual trigger by host via POST with { event_id }.
 *
 * Cron schedule (set in Supabase Dashboard):
 *   0 9 * * *   (every day at 09:00 KST = 00:00 UTC)
 *
 * Required secrets (set via supabase secrets set):
 *   - FCM_PROJECT_ID
 *   - FCM_CLIENT_EMAIL
 *   - FCM_PRIVATE_KEY
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.103.0";

interface FCMMessage {
  token: string;
  notification: { title: string; body: string };
  webpush?: {
    fcm_options: { link: string };
  };
}

function base64url(str: string): string {
  return btoa(str).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

// Google OAuth2 token for FCM v1 API
async function getAccessToken(
  clientEmail: string,
  privateKey: string,
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = base64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const payload = base64url(
    JSON.stringify({
      iss: clientEmail,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    }),
  );

  const signInput = `${header}.${payload}`;

  // Import the private key for signing
  const pemContents = privateKey
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\n/g, "");
  const binaryKey = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(signInput),
  );

  const jwt = `${signInput}.${base64url(
    String.fromCharCode(...new Uint8Array(signature)),
  )}`;

  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const data = await tokenResponse.json();
  if (!data.access_token) {
    throw new Error(`FCM auth failed: ${JSON.stringify(data)}`);
  }
  return data.access_token as string;
}

async function sendFCMMessage(
  projectId: string,
  accessToken: string,
  message: FCMMessage,
): Promise<{ success: boolean; token: string; error?: string }> {
  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ message }),
  });

  if (res.ok) {
    return { success: true, token: message.token };
  }

  const error = await res.text();
  return { success: false, token: message.token, error };
}

Deno.serve(async (req) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const projectId = Deno.env.get("FCM_PROJECT_ID")!;
  const clientEmail = Deno.env.get("FCM_CLIENT_EMAIL")!;
  const privateKey = Deno.env.get("FCM_PRIVATE_KEY")!.replace(/\\n/g, "\n");
  const siteUrl = Deno.env.get("SITE_URL") ?? "https://moment.app";

  let targetEventIds: string[] = [];
  let isManual = false;

  // Manual trigger: POST { event_id }
  if (req.method === "POST") {
    const body = await req.json();
    if (body.event_id) {
      targetEventIds = [body.event_id];
      isManual = true;
    }
  }

  // D-1 auto: find events in 23–25h window
  if (targetEventIds.length === 0) {
    const now = new Date();
    const windowStart = new Date(now.getTime() + 23 * 60 * 60 * 1000);
    const windowEnd = new Date(now.getTime() + 25 * 60 * 60 * 1000);

    const { data: events, error: eventsError } = await supabase
      .from("events")
      .select("id")
      .gte("datetime", windowStart.toISOString())
      .lte("datetime", windowEnd.toISOString());

    if (eventsError) {
      return new Response(JSON.stringify({ error: eventsError.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (!events || events.length === 0) {
      return new Response(
        JSON.stringify({ message: "No events in D-1 window" }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    }

    // Filter out events that already have a d1 reminder
    const eventIds = events.map((e) => e.id);
    const { data: existingReminders } = await supabase
      .from("reminders")
      .select("event_id")
      .in("event_id", eventIds)
      .eq("type", "d1");

    const alreadySent = new Set(
      (existingReminders ?? []).map((r) => r.event_id),
    );
    targetEventIds = eventIds.filter((id) => !alreadySent.has(id));
  }

  if (targetEventIds.length === 0) {
    return new Response(
      JSON.stringify({ message: "All D-1 reminders already sent" }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  }

  // Get FCM access token
  let accessToken: string;
  try {
    accessToken = await getAccessToken(clientEmail, privateKey);
  } catch (err) {
    return new Response(
      JSON.stringify({ error: `FCM auth error: ${(err as Error).message}` }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  const results: Array<{
    event_id: string;
    sent: number;
    failed: number;
    errors: string[];
  }> = [];

  for (const eventId of targetEventIds) {
    // Get event details
    const { data: event } = await supabase
      .from("events")
      .select("id, title, datetime, location")
      .eq("id", eventId)
      .single();

    if (!event) continue;

    // Get attending guest user IDs
    const { data: guests } = await supabase
      .from("guest_states")
      .select("user_id")
      .eq("event_id", eventId)
      .eq("status", "attending");

    if (!guests || guests.length === 0) {
      results.push({ event_id: eventId, sent: 0, failed: 0, errors: [] });
      continue;
    }

    // Get host ID
    const { data: eventHost } = await supabase
      .from("events")
      .select("host_id")
      .eq("id", eventId)
      .single();

    const eventDate = new Date(event.datetime);
    const dateStr = `${eventDate.getMonth() + 1}/${eventDate.getDate()}`;
    const timeStr = `${eventDate.getHours().toString().padStart(2, "0")}:${eventDate.getMinutes().toString().padStart(2, "0")}`;

    // Collect all user IDs (guests + host) and fetch their FCM tokens
    const userIds = new Set(guests.map((g) => g.user_id));
    if (eventHost?.host_id) {
      userIds.add(eventHost.host_id);
    }

    const { data: fcmRecords } = await supabase
      .from("fcm_tokens")
      .select("token")
      .in("user_id", Array.from(userIds));

    const tokenSet = new Set<string>();
    for (const record of fcmRecords ?? []) {
      if (record.token) {
        tokenSet.add(record.token);
      }
    }

    const tokens = Array.from(tokenSet);
    let sent = 0;
    let failed = 0;
    const errors: string[] = [];

    // Send FCM messages
    const sendPromises = tokens.map((token) =>
      sendFCMMessage(projectId, accessToken, {
        token,
        notification: {
          title: `내일 모임이 있어요! 🎉`,
          body: `${event.title} — ${dateStr} ${timeStr}${event.location ? ` @ ${event.location}` : ""}`,
        },
        webpush: {
          fcm_options: { link: `${siteUrl}/event/${eventId}` },
        },
      }),
    );

    const sendResults = await Promise.allSettled(sendPromises);
    for (const result of sendResults) {
      if (result.status === "fulfilled" && result.value.success) {
        sent++;
      } else {
        failed++;
        const errMsg =
          result.status === "fulfilled"
            ? result.value.error
            : (result.reason as Error).message;
        if (errMsg) errors.push(errMsg);
      }
    }

    // Log reminder
    const batchId = crypto.randomUUID();
    await supabase.from("reminders").insert({
      event_id: eventId,
      type: isManual ? "manual" : "d1",
      fcm_batch_id: batchId,
    });

    results.push({ event_id: eventId, sent, failed, errors });
  }

  return new Response(JSON.stringify({ results }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
