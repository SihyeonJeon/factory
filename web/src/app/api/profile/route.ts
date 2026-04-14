import { NextResponse } from "next/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export async function PATCH(request: Request) {
  const supabase = await createServerSupabaseClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "로그인이 필요합니다" }, { status: 401 });
  }

  let body: { displayName?: string };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "잘못된 요청입니다" }, { status: 400 });
  }

  const { displayName } = body;

  if (typeof displayName !== "string") {
    return NextResponse.json(
      { error: "이름은 필수 항목입니다" },
      { status: 400 },
    );
  }

  const trimmed = displayName.trim();

  if (trimmed.length < 1 || trimmed.length > 30) {
    return NextResponse.json(
      { error: "이름은 1~30자로 입력해주세요" },
      { status: 400 },
    );
  }

  const { data, error } = await supabase
    .from("profiles")
    .update({ display_name: trimmed })
    .eq("id", user.id)
    .select("id, display_name, avatar_url")
    .single();

  if (error) {
    return NextResponse.json(
      { error: "프로필 수정에 실패했습니다" },
      { status: 500 },
    );
  }

  return NextResponse.json({ profile: data });
}
