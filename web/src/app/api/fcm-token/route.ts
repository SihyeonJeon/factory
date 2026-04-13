import { NextResponse } from "next/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";

/**
 * POST /api/fcm-token
 * Save or update the FCM token for the authenticated user.
 * Body: { token: string }
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
  const token = body.token;

  if (typeof token !== "string" || token.length === 0) {
    return NextResponse.json(
      { error: "Missing or invalid token" },
      { status: 400 },
    );
  }

  const { error } = await supabase
    .from("fcm_tokens")
    .upsert({
      user_id: user.id,
      token,
      updated_at: new Date().toISOString(),
    });

  if (error) {
    console.error("FCM token save error:", error);
    return NextResponse.json({ error: "토큰 저장에 실패했습니다" }, { status: 500 });
  }

  return NextResponse.json({ success: true });
}
