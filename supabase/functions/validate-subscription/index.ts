import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Origin": "*",
  "Content-Type": "application/json",
};

type ValidateSubscriptionRequest = {
  originalTransactionId?: string;
  productId?: string;
  bundleId?: string;
  environment?: string;
};

const json = (status: number, body: Record<string, unknown>) =>
  new Response(JSON.stringify(body), {
    status,
    headers: corsHeaders,
  });

const normalizeEnvironment = (value: string | undefined): "production" | "sandbox" => {
  if (value === "production") return "production";
  return "sandbox";
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json(405, { ok: false, error: "method_not_allowed" });
  }

  const authorization = req.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) {
    return json(401, { ok: false, error: "missing_authorization" });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !supabaseAnonKey || !supabaseServiceRoleKey) {
    return json(500, { ok: false, error: "missing_supabase_env" });
  }

  let payload: ValidateSubscriptionRequest;
  try {
    payload = await req.json();
  } catch {
    return json(400, { ok: false, error: "invalid_json" });
  }

  if (
    !payload.originalTransactionId ||
    !payload.productId ||
    !payload.bundleId ||
    !payload.environment
  ) {
    return json(400, { ok: false, error: "missing_fields" });
  }

  const authClient = createClient(supabaseUrl, supabaseAnonKey, {
    auth: { autoRefreshToken: false, persistSession: false },
    global: { headers: { Authorization: authorization } },
  });

  const {
    data: { user },
    error: userError,
  } = await authClient.auth.getUser();

  if (userError || !user) {
    return json(401, { ok: false, error: "invalid_jwt" });
  }

  const admin = createClient(supabaseUrl, supabaseServiceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const now = new Date().toISOString();
  const status = "active";
  const expiresAt = null;
  const environment = normalizeEnvironment(payload.environment);

  // TODO(R42): Replace client-claim trust with App Store Server API verification.
  // v1 writes a best-effort mirror row so the backend can observe the claimed subscription state.
  const { error: upsertError } = await admin.from("subscriptions").upsert(
    {
      user_id: user.id,
      product_id: payload.productId,
      original_transaction_id: payload.originalTransactionId,
      purchased_at: now,
      expires_at: expiresAt,
      status,
      auto_renew: true,
      environment,
      updated_at: now,
    },
    { onConflict: "user_id" },
  );

  if (upsertError) {
    return json(500, { ok: false, error: "upsert_failed", details: upsertError.message });
  }

  return json(200, {
    ok: true,
    status,
    expires_at: expiresAt,
  });
});
