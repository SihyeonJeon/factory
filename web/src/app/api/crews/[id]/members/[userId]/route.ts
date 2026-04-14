import { NextResponse } from "next/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

type Props = {
  params: Promise<{ id: string; userId: string }>;
};

/**
 * DELETE /api/crews/[id]/members/[userId]
 * Remove a member from a crew. Allowed for:
 * - The member themselves (leaving)
 * - A crew admin (kicking)
 */
export async function DELETE(_request: Request, { params }: Props) {
  const { id: crewId, userId: targetUserId } = await params;

  if (!UUID_RE.test(crewId) || !UUID_RE.test(targetUserId)) {
    return NextResponse.json({ error: "잘못된 요청입니다" }, { status: 400 });
  }

  const supabase = await createServerSupabaseClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "로그인이 필요합니다" }, { status: 401 });
  }

  const isSelf = user.id === targetUserId;

  if (!isSelf) {
    // Only admins can remove other members
    const { data: isAdmin } = await supabase.rpc("is_crew_admin", {
      p_crew_id: crewId,
      p_user_id: user.id,
    });

    if (!isAdmin) {
      return NextResponse.json(
        { error: "멤버 제거 권한이 없습니다" },
        { status: 403 },
      );
    }
  }

  const { error, count } = await supabase
    .from("crew_members")
    .delete({ count: "exact" })
    .eq("crew_id", crewId)
    .eq("user_id", targetUserId);

  if (error) {
    console.error("Remove member error:", error);
    return NextResponse.json(
      { error: "멤버 제거에 실패했습니다" },
      { status: 500 },
    );
  }

  if (count === 0) {
    return NextResponse.json(
      { error: "해당 멤버를 찾을 수 없습니다" },
      { status: 404 },
    );
  }

  return NextResponse.json({ ok: true });
}
