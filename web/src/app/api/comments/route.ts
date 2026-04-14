import { NextResponse } from "next/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const MAX_BODY_LENGTH = 500;

export async function POST(request: Request) {
  const supabase = await createServerSupabaseClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "로그인이 필요합니다" }, { status: 401 });
  }

  let body: { eventId: string; body: string };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "잘못된 요청입니다" }, { status: 400 });
  }

  const { eventId, body: commentBody } = body;

  if (!eventId || !commentBody) {
    return NextResponse.json(
      { error: "이벤트 ID와 코멘트 내용이 필요합니다" },
      { status: 400 },
    );
  }

  // Validate eventId is a proper UUID (S-013)
  if (!UUID_RE.test(eventId)) {
    return NextResponse.json(
      { error: "잘못된 이벤트 ID입니다" },
      { status: 400 },
    );
  }

  // Validate body length (S-003)
  if (typeof commentBody !== "string") {
    return NextResponse.json({ error: "잘못된 요청입니다" }, { status: 400 });
  }

  const trimmed = commentBody.trim();
  if (trimmed.length === 0 || trimmed.length > MAX_BODY_LENGTH) {
    return NextResponse.json(
      { error: `코멘트는 1~${MAX_BODY_LENGTH}자여야 합니다` },
      { status: 400 },
    );
  }

  // Insert comment — RLS enforces participant-only access
  const { data, error } = await supabase
    .from("event_comments")
    .insert({
      event_id: eventId,
      author_id: user.id,
      body: trimmed,
    })
    .select("id, body, created_at")
    .single();

  if (error) {
    console.error("Comment insert error:", error);
    return NextResponse.json(
      { error: "코멘트 등록에 실패했습니다" },
      { status: 500 },
    );
  }

  return NextResponse.json({
    id: data.id,
    body: data.body,
    createdAt: data.created_at,
  });
}
