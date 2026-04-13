import { NextResponse } from "next/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { getMoodTemplate } from "@/lib/mood-templates";
import type { EventMoodEnum } from "@/lib/database.types";

const VALID_MOODS: ReadonlySet<string> = new Set<string>([
  "birthday", "running", "wine", "book", "houseparty", "salon",
]);
const MAX_TITLE_LENGTH = 100;
const MAX_DESCRIPTION_LENGTH = 2000;
const MAX_LOCATION_LENGTH = 200;

export async function POST(request: Request) {
  const supabase = await createServerSupabaseClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json();
  const { mood, title, datetime, location, description, coverImageUrl } =
    body as {
      mood: EventMoodEnum;
      title: string;
      datetime: string;
      location: string;
      description: string;
      coverImageUrl: string | null;
    };

  if (!title || !datetime) {
    return NextResponse.json(
      { error: "title and datetime are required" },
      { status: 400 },
    );
  }

  // Validate mood enum
  if (mood && !VALID_MOODS.has(mood)) {
    return NextResponse.json(
      { error: "유효하지 않은 무드입니다" },
      { status: 400 },
    );
  }

  // Validate field lengths
  if (typeof title !== "string" || title.length > MAX_TITLE_LENGTH) {
    return NextResponse.json(
      { error: `제목은 ${MAX_TITLE_LENGTH}자 이하여야 합니다` },
      { status: 400 },
    );
  }

  if (description && typeof description === "string" && description.length > MAX_DESCRIPTION_LENGTH) {
    return NextResponse.json(
      { error: `설명은 ${MAX_DESCRIPTION_LENGTH}자 이하여야 합니다` },
      { status: 400 },
    );
  }

  if (location && typeof location === "string" && location.length > MAX_LOCATION_LENGTH) {
    return NextResponse.json(
      { error: `장소는 ${MAX_LOCATION_LENGTH}자 이하여야 합니다` },
      { status: 400 },
    );
  }

  // Validate datetime is valid ISO string
  if (typeof datetime !== "string" || isNaN(Date.parse(datetime))) {
    return NextResponse.json(
      { error: "유효한 날짜/시간을 입력해주세요" },
      { status: 400 },
    );
  }

  // Validate coverImageUrl: must be a Supabase storage path or null
  if (coverImageUrl !== null && coverImageUrl !== undefined) {
    if (typeof coverImageUrl !== "string" || coverImageUrl.length > 2048) {
      return NextResponse.json(
        { error: "유효하지 않은 커버 이미지 URL입니다" },
        { status: 400 },
      );
    }
    // Only allow Supabase storage paths (covers/xxx.ext) or Supabase storage URLs
    const supabaseHost = process.env.NEXT_PUBLIC_SUPABASE_URL ?? "";
    const isStoragePath = /^covers\/[a-f0-9-]+\.\w+$/i.test(coverImageUrl);
    const isSupabaseUrl = supabaseHost && coverImageUrl.startsWith(supabaseHost);
    if (!isStoragePath && !isSupabaseUrl) {
      return NextResponse.json(
        { error: "커버 이미지는 업로드된 파일만 사용할 수 있습니다" },
        { status: 400 },
      );
    }
  }

  const template = getMoodTemplate(mood);
  const colorTheme = template?.colorTheme ?? {
    primary: "#8B5CF6",
    bg: "#F5F0FF",
    accent: "#6D28D9",
  };

  const { data, error } = await supabase
    .from("events")
    .insert({
      host_id: user.id,
      title,
      datetime,
      location: location || "",
      mood: mood || "wine",
      cover_image_url: coverImageUrl,
      color_theme: colorTheme,
      description: description || "",
      has_fee: false,
    })
    .select("id")
    .single();

  if (error) {
    console.error("Event creation error:", error);
    return NextResponse.json({ error: "이벤트 생성에 실패했습니다" }, { status: 500 });
  }

  return NextResponse.json({ id: data.id });
}
