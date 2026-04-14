import { NextResponse } from "next/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import type { Database } from "@/lib/database.types";

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const MAX_TITLE_LENGTH = 100;
const MAX_DESCRIPTION_LENGTH = 2000;
const MAX_LOCATION_LENGTH = 200;

type Props = {
  params: Promise<{ id: string }>;
};

/**
 * PATCH /api/events/[id]
 * Host-only: update title, datetime, location, description, hasFee.
 * Mood and cover image are immutable after creation (design consistency).
 */
export async function PATCH(request: Request, { params }: Props) {
  const { id } = await params;
  if (!UUID_RE.test(id)) {
    return NextResponse.json({ error: "잘못된 요청입니다" }, { status: 400 });
  }

  const supabase = await createServerSupabaseClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "로그인이 필요합니다" }, { status: 401 });
  }

  let body: {
    title?: string;
    datetime?: string;
    location?: string;
    description?: string;
    hasFee?: boolean;
  };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "잘못된 요청입니다" }, { status: 400 });
  }

  // Verify host ownership
  const { data: event } = await supabase
    .from("events")
    .select("host_id")
    .eq("id", id)
    .single();

  if (!event) {
    return NextResponse.json({ error: "이벤트를 찾을 수 없습니다" }, { status: 404 });
  }

  if (event.host_id !== user.id) {
    return NextResponse.json({ error: "수정 권한이 없습니다" }, { status: 403 });
  }

  // Build update object with validation
  const updates: Database["public"]["Tables"]["events"]["Update"] = {};

  if (body.title !== undefined) {
    if (typeof body.title !== "string") {
      return NextResponse.json({ error: "잘못된 요청입니다" }, { status: 400 });
    }
    const trimmed = body.title.trim();
    if (trimmed.length === 0 || trimmed.length > MAX_TITLE_LENGTH) {
      return NextResponse.json({ error: `제목은 1~${MAX_TITLE_LENGTH}자여야 합니다` }, { status: 400 });
    }
    updates.title = trimmed;
  }

  if (body.datetime !== undefined) {
    if (typeof body.datetime !== "string" || isNaN(Date.parse(body.datetime))) {
      return NextResponse.json({ error: "유효한 날짜/시간을 입력해주세요" }, { status: 400 });
    }
    updates.datetime = body.datetime;
  }

  if (body.location !== undefined) {
    if (typeof body.location !== "string") {
      return NextResponse.json({ error: "잘못된 요청입니다" }, { status: 400 });
    }
    const trimmed = body.location.trim();
    if (trimmed.length > MAX_LOCATION_LENGTH) {
      return NextResponse.json({ error: `장소는 ${MAX_LOCATION_LENGTH}자 이하여야 합니다` }, { status: 400 });
    }
    updates.location = trimmed;
  }

  if (body.description !== undefined) {
    if (typeof body.description !== "string") {
      return NextResponse.json({ error: "잘못된 요청입니다" }, { status: 400 });
    }
    const trimmed = body.description.trim();
    if (trimmed.length > MAX_DESCRIPTION_LENGTH) {
      return NextResponse.json({ error: `설명은 ${MAX_DESCRIPTION_LENGTH}자 이하여야 합니다` }, { status: 400 });
    }
    updates.description = trimmed;
  }

  if (body.hasFee !== undefined) {
    if (typeof body.hasFee !== "boolean") {
      return NextResponse.json({ error: "잘못된 요청입니다" }, { status: 400 });
    }
    updates.has_fee = body.hasFee;
  }

  if (Object.keys(updates).length === 0) {
    return NextResponse.json({ error: "변경할 항목이 없습니다" }, { status: 400 });
  }

  const { error } = await supabase
    .from("events")
    .update(updates)
    .eq("id", id);

  if (error) {
    console.error("Event update error:", error);
    return NextResponse.json({ error: "이벤트 수정에 실패했습니다" }, { status: 500 });
  }

  return NextResponse.json({ ok: true });
}
