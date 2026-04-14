import { NextResponse } from "next/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { getMoodTemplate } from "@/lib/mood-templates";
import type { EventMoodEnum } from "@/lib/database.types";

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const VALID_MOODS: ReadonlySet<string> = new Set<string>([
  "birthday", "running", "wine", "book", "houseparty", "salon",
]);
const MAX_TITLE_LENGTH = 100;
const MAX_DESCRIPTION_LENGTH = 2000;
const MAX_LOCATION_LENGTH = 200;
const MAX_COVER_SIZE = 10 * 1024 * 1024; // 10MB
const ALLOWED_IMAGE_TYPES = new Set([
  "image/jpeg", "image/png", "image/webp", "image/heic",
]);

export async function POST(request: Request) {
  const supabase = await createServerSupabaseClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "로그인이 필요합니다" }, { status: 401 });
  }

  // Parse FormData (cover file uploaded server-side for Storage RLS compliance)
  let formData: FormData;
  try {
    formData = await request.formData();
  } catch {
    return NextResponse.json({ error: "잘못된 요청입니다" }, { status: 400 });
  }

  const mood = (formData.get("mood") as string) || "wine";
  const title = ((formData.get("title") as string) ?? "").trim();
  const datetime = (formData.get("datetime") as string) ?? "";
  const location = ((formData.get("location") as string) ?? "").trim();
  const description = ((formData.get("description") as string) ?? "").trim();
  const hasFee = formData.get("hasFee") === "true";
  const coverFile = formData.get("coverFile") as File | null;
  const coverImageUrl = (formData.get("coverImageUrl") as string) || null;
  const crewId = (formData.get("crewId") as string) || null;

  // Validate required fields
  if (!title || !datetime) {
    return NextResponse.json(
      { error: "제목과 날짜/시간은 필수입니다" },
      { status: 400 },
    );
  }

  if (!VALID_MOODS.has(mood)) {
    return NextResponse.json(
      { error: "유효하지 않은 무드입니다" },
      { status: 400 },
    );
  }

  if (title.length > MAX_TITLE_LENGTH) {
    return NextResponse.json(
      { error: `제목은 ${MAX_TITLE_LENGTH}자 이하여야 합니다` },
      { status: 400 },
    );
  }

  if (description.length > MAX_DESCRIPTION_LENGTH) {
    return NextResponse.json(
      { error: `설명은 ${MAX_DESCRIPTION_LENGTH}자 이하여야 합니다` },
      { status: 400 },
    );
  }

  if (location.length > MAX_LOCATION_LENGTH) {
    return NextResponse.json(
      { error: `장소는 ${MAX_LOCATION_LENGTH}자 이하여야 합니다` },
      { status: 400 },
    );
  }

  if (isNaN(Date.parse(datetime))) {
    return NextResponse.json(
      { error: "유효한 날짜/시간을 입력해주세요" },
      { status: 400 },
    );
  }

  // Validate cover file if provided
  if (coverFile && coverFile.size > 0) {
    if (coverFile.size > MAX_COVER_SIZE) {
      return NextResponse.json(
        { error: "커버 이미지는 10MB 이하여야 합니다" },
        { status: 400 },
      );
    }
    if (!ALLOWED_IMAGE_TYPES.has(coverFile.type)) {
      return NextResponse.json(
        { error: "지원하지 않는 이미지 형식입니다 (JPEG, PNG, WebP, HEIC만 가능)" },
        { status: 400 },
      );
    }
  }

  // Validate default cover path if provided (SVG from public/)
  if (coverImageUrl && !/^\/?covers\/[\w-]+\.\w+$/i.test(coverImageUrl)) {
    return NextResponse.json(
      { error: "유효하지 않은 커버 이미지입니다" },
      { status: 400 },
    );
  }

  // Validate crewId if provided
  if (crewId) {
    if (!UUID_RE.test(crewId)) {
      return NextResponse.json(
        { error: "잘못된 아크 ID입니다" },
        { status: 400 },
      );
    }
    const { data: isMember } = await supabase.rpc("is_crew_member", {
      p_crew_id: crewId,
      p_user_id: user.id,
    });
    if (!isMember) {
      return NextResponse.json(
        { error: "해당 아크의 멤버가 아닙니다" },
        { status: 403 },
      );
    }
  }

  const template = getMoodTemplate(mood);
  const colorTheme = template?.colorTheme ?? {
    primary: "#8B5CF6",
    bg: "#F5F0FF",
    accent: "#6D28D9",
  };

  // 1. Create event first (need event ID for storage path)
  const { data, error } = await supabase
    .from("events")
    .insert({
      host_id: user.id,
      title,
      datetime,
      location,
      mood: mood as EventMoodEnum,
      cover_image_url: coverImageUrl, // default cover or null initially
      color_theme: colorTheme,
      description,
      has_fee: hasFee,
      crew_id: crewId,
    })
    .select("id")
    .single();

  if (error) {
    console.error("Event creation error:", error);
    return NextResponse.json({ error: "이벤트 생성에 실패했습니다" }, { status: 500 });
  }

  const eventId = data.id;

  // 2. Upload cover file server-side if provided
  // Path: {event_id}/{host_id}/cover.{ext} — matches Storage RLS policy
  if (coverFile && coverFile.size > 0) {
    const ext = coverFile.name.split(".").pop()?.toLowerCase() ?? "jpg";
    const storagePath = `${eventId}/${user.id}/cover.${ext}`;
    const buffer = Buffer.from(await coverFile.arrayBuffer());

    const { error: uploadError } = await supabase.storage
      .from("event-media")
      .upload(storagePath, buffer, {
        contentType: coverFile.type,
        upsert: true,
      });

    if (uploadError) {
      console.error("Cover upload error:", uploadError);
      // Event created but cover failed — update with null and continue
    } else {
      // Update event with the storage path
      await supabase
        .from("events")
        .update({ cover_image_url: storagePath })
        .eq("id", eventId);
    }
  }

  return NextResponse.json({ id: eventId });
}
