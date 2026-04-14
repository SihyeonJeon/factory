import { NextResponse } from "next/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

type Props = {
  params: Promise<{ id: string }>;
};

/**
 * DELETE /api/comments/[id]
 * Delete own comment, or any comment if user is event host.
 * RLS also enforces this on the database side.
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

  // Fetch the comment to verify ownership or host status
  const { data: comment, error: fetchError } = await supabase
    .from("event_comments")
    .select("id, author_id, event_id")
    .eq("id", id)
    .single();

  if (fetchError || !comment) {
    return NextResponse.json(
      { error: "코멘트를 찾을 수 없습니다" },
      { status: 404 },
    );
  }

  // Check if user is author or event host
  if (comment.author_id !== user.id) {
    const { data: event } = await supabase
      .from("events")
      .select("host_id")
      .eq("id", comment.event_id)
      .single();

    if (!event || event.host_id !== user.id) {
      return NextResponse.json(
        { error: "삭제 권한이 없습니다" },
        { status: 403 },
      );
    }
  }

  const { error } = await supabase
    .from("event_comments")
    .delete()
    .eq("id", id);

  if (error) {
    console.error("Comment delete error:", error);
    return NextResponse.json(
      { error: "코멘트 삭제에 실패했습니다" },
      { status: 500 },
    );
  }

  return NextResponse.json({ ok: true });
}
