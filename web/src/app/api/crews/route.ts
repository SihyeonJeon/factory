import { NextResponse } from "next/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";

const MAX_NAME_LENGTH = 50;
const MAX_DESCRIPTION_LENGTH = 500;

export async function POST(request: Request) {
  const supabase = await createServerSupabaseClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "로그인이 필요합니다" }, { status: 401 });
  }

  let body: { name?: string; description?: string };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "잘못된 요청입니다" }, { status: 400 });
  }

  if (typeof body.name !== "string") {
    return NextResponse.json({ error: "잘못된 요청입니다" }, { status: 400 });
  }

  const name = body.name.trim();
  if (name.length === 0 || name.length > MAX_NAME_LENGTH) {
    return NextResponse.json(
      { error: `아크 이름은 1~${MAX_NAME_LENGTH}자여야 합니다` },
      { status: 400 },
    );
  }

  const description = (body.description ?? "").trim();
  if (description.length > MAX_DESCRIPTION_LENGTH) {
    return NextResponse.json(
      { error: `설명은 ${MAX_DESCRIPTION_LENGTH}자 이하여야 합니다` },
      { status: 400 },
    );
  }

  const { data, error } = await supabase.rpc("create_crew", {
    p_name: name,
    p_description: description,
  });

  if (error) {
    console.error("Crew creation error:", error);
    return NextResponse.json(
      { error: "아크 생성에 실패했습니다" },
      { status: 500 },
    );
  }

  // Fetch the invite code for the newly created crew
  const { data: crew } = await supabase
    .from("crews")
    .select("invite_code")
    .eq("id", data)
    .single();

  return NextResponse.json({
    id: data,
    inviteCode: crew?.invite_code ?? null,
  });
}
