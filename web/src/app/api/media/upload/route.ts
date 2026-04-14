import { NextResponse } from "next/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";

const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10 MB
const ALLOWED_TYPES = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/heic",
]);
const MAX_PHOTOS_PER_EVENT = 10;

/**
 * POST /api/media/upload
 * Upload a photo to event-media bucket and insert media_timeline record.
 *
 * FormData fields:
 *   - file: File
 *   - eventId: string (UUID)
 *   - width: string (number)
 *   - height: string (number)
 */
export async function POST(request: Request) {
  const supabase = await createServerSupabaseClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const formData = await request.formData();
  const file = formData.get("file") as File | null;
  const eventId = formData.get("eventId") as string | null;
  const widthStr = formData.get("width") as string | null;
  const heightStr = formData.get("height") as string | null;

  if (!file || !eventId) {
    return NextResponse.json(
      { error: "file and eventId are required" },
      { status: 400 },
    );
  }

  // Validate eventId is a proper UUID
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(eventId)) {
    return NextResponse.json(
      { error: "잘못된 이벤트 ID입니다" },
      { status: 400 },
    );
  }

  // Verify user is host or guest of this event
  const { data: event } = await supabase
    .from("events")
    .select("host_id")
    .eq("id", eventId)
    .single();

  if (!event) {
    return NextResponse.json(
      { error: "이벤트를 찾을 수 없습니다" },
      { status: 404 },
    );
  }

  if (event.host_id !== user.id) {
    const { data: guest } = await supabase
      .from("guest_states")
      .select("id")
      .eq("event_id", eventId)
      .eq("user_id", user.id)
      .single();

    if (!guest) {
      return NextResponse.json(
        { error: "이 이벤트에 사진을 업로드할 권한이 없습니다" },
        { status: 403 },
      );
    }
  }

  // Validate file type & size
  if (!ALLOWED_TYPES.has(file.type)) {
    return NextResponse.json(
      { error: "JPG, PNG, WebP, HEIC 이미지만 업로드할 수 있어요" },
      { status: 400 },
    );
  }
  if (file.size > MAX_FILE_SIZE) {
    return NextResponse.json(
      { error: "10MB 이하의 이미지만 업로드할 수 있어요" },
      { status: 400 },
    );
  }

  // Check photo limit for this event
  const { count } = await supabase
    .from("media_timeline")
    .select("id", { count: "exact", head: true })
    .eq("event_id", eventId);

  if (count !== null && count >= MAX_PHOTOS_PER_EVENT) {
    return NextResponse.json(
      { error: "이 이벤트의 최대 사진 수에 도달했어요" },
      { status: 400 },
    );
  }

  // Build storage path
  const ext = file.name.split(".").pop()?.toLowerCase() ?? "jpg";
  const uniqueId = crypto.randomUUID();
  const storagePath = `${eventId}/${user.id}/${uniqueId}.${ext}`;

  // Upload to Storage
  const { error: uploadError } = await supabase.storage
    .from("event-media")
    .upload(storagePath, file, {
      contentType: file.type,
      upsert: false,
    });

  if (uploadError) {
    console.error("Storage upload error:", uploadError);
    return NextResponse.json(
      { error: "이미지 업로드에 실패했습니다" },
      { status: 500 },
    );
  }

  // Get signed URL
  const { data: urlData } = await supabase.storage
    .from("event-media")
    .createSignedUrl(storagePath, 60 * 60 * 24 * 7);

  const signedUrl = urlData?.signedUrl ?? "";

  const width = widthStr ? parseInt(widthStr, 10) : null;
  const height = heightStr ? parseInt(heightStr, 10) : null;

  // Insert media_timeline record
  const { data, error: insertError } = await supabase
    .from("media_timeline")
    .insert({
      event_id: eventId,
      uploader_id: user.id,
      storage_path: storagePath,
      thumbnail_path: storagePath,
      width,
      height,
    })
    .select("id, uploaded_at")
    .single();

  if (insertError) {
    console.error("Media record insert error:", insertError);
    // Clean up on failure
    await supabase.storage.from("event-media").remove([storagePath]);
    return NextResponse.json(
      { error: "사진 기록 저장에 실패했습니다" },
      { status: 500 },
    );
  }

  // Secondary photo cap check: guard against race conditions where
  // concurrent uploads passed the initial count check simultaneously.
  const { count: postInsertCount } = await supabase
    .from("media_timeline")
    .select("id", { count: "exact", head: true })
    .eq("event_id", eventId);

  if (postInsertCount !== null && postInsertCount > MAX_PHOTOS_PER_EVENT) {
    // Over limit — roll back the just-inserted record and storage file
    await supabase.from("media_timeline").delete().eq("id", data.id);
    await supabase.storage.from("event-media").remove([storagePath]);
    return NextResponse.json(
      { error: "이 이벤트의 최대 사진 수에 도달했어요" },
      { status: 409 },
    );
  }

  // Fetch uploader profile for response
  const { data: profile } = await supabase
    .from("profiles")
    .select("display_name, avatar_url")
    .eq("id", user.id)
    .single();

  return NextResponse.json({
    id: data.id,
    eventId,
    url: signedUrl,
    thumbnailUrl: signedUrl,
    uploaderName: profile?.display_name ?? "",
    uploaderAvatar: profile?.avatar_url ?? null,
    uploadedAt: data.uploaded_at,
    width,
    height,
  });
}
