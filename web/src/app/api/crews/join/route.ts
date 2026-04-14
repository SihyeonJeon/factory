import { NextResponse } from "next/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export async function POST(request: Request) {
  const supabase = await createServerSupabaseClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "로그인이 필요합니다" }, { status: 401 });
  }

  let body: { inviteCode?: string };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "잘못된 요청입니다" }, { status: 400 });
  }

  if (typeof body.inviteCode !== "string" || body.inviteCode.trim().length === 0) {
    return NextResponse.json(
      { error: "초대 코드를 입력해주세요" },
      { status: 400 },
    );
  }

  const inviteCode = body.inviteCode.trim();

  const { data, error } = await supabase.rpc("join_crew_by_invite", {
    p_invite_code: inviteCode,
  });

  if (error) {
    console.error("Join crew error:", error);
    if (error.message?.includes("Invalid invite code")) {
      return NextResponse.json(
        { error: "유효하지 않은 초대 코드입니다" },
        { status: 404 },
      );
    }
    return NextResponse.json(
      { error: "아크 참가에 실패했습니다" },
      { status: 500 },
    );
  }

  return NextResponse.json({ crewId: data });
}
