import { NextResponse } from "next/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import type { Database } from "@/lib/database.types";

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const MAX_NAME_LENGTH = 50;
const MAX_DESCRIPTION_LENGTH = 500;

type Props = {
  params: Promise<{ id: string }>;
};

/**
 * PATCH /api/crews/[id]
 * Admin-only: update crew name and/or description.
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

  // Admin check
  const { data: isAdmin } = await supabase.rpc("is_crew_admin", {
    p_crew_id: id,
    p_user_id: user.id,
  });

  if (!isAdmin) {
    return NextResponse.json({ error: "수정 권한이 없습니다" }, { status: 403 });
  }

  let body: { name?: string; description?: string };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "잘못된 요청입니다" }, { status: 400 });
  }

  const updates: Database["public"]["Tables"]["crews"]["Update"] = {};

  if (body.name !== undefined) {
    if (typeof body.name !== "string") {
      return NextResponse.json({ error: "잘못된 요청입니다" }, { status: 400 });
    }
    const trimmed = body.name.trim();
    if (trimmed.length === 0 || trimmed.length > MAX_NAME_LENGTH) {
      return NextResponse.json(
        { error: `아크 이름은 1~${MAX_NAME_LENGTH}자여야 합니다` },
        { status: 400 },
      );
    }
    updates.name = trimmed;
  }

  if (body.description !== undefined) {
    if (typeof body.description !== "string") {
      return NextResponse.json({ error: "잘못된 요청입니다" }, { status: 400 });
    }
    const trimmed = body.description.trim();
    if (trimmed.length > MAX_DESCRIPTION_LENGTH) {
      return NextResponse.json(
        { error: `설명은 ${MAX_DESCRIPTION_LENGTH}자 이하여야 합니다` },
        { status: 400 },
      );
    }
    updates.description = trimmed;
  }

  if (Object.keys(updates).length === 0) {
    return NextResponse.json(
      { error: "변경할 항목이 없습니다" },
      { status: 400 },
    );
  }

  const { error } = await supabase.from("crews").update(updates).eq("id", id);

  if (error) {
    console.error("Crew update error:", error);
    return NextResponse.json(
      { error: "아크 수정에 실패했습니다" },
      { status: 500 },
    );
  }

  return NextResponse.json({ ok: true });
}

/**
 * DELETE /api/crews/[id]
 * Admin-only: delete crew entirely.
 */
export async function DELETE(_request: Request, { params }: Props) {
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

  // Admin check
  const { data: isAdmin } = await supabase.rpc("is_crew_admin", {
    p_crew_id: id,
    p_user_id: user.id,
  });

  if (!isAdmin) {
    return NextResponse.json({ error: "삭제 권한이 없습니다" }, { status: 403 });
  }

  const { error } = await supabase.from("crews").delete().eq("id", id);

  if (error) {
    console.error("Crew delete error:", error);
    return NextResponse.json(
      { error: "아크 삭제에 실패했습니다" },
      { status: 500 },
    );
  }

  return NextResponse.json({ ok: true });
}
