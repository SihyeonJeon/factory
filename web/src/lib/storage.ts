import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "./database.types";

const BUCKET = "event-media";
const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10 MB
const ALLOWED_TYPES = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/heic",
]);

export interface UploadResult {
  storagePath: string;
  publicUrl: string;
}

/**
 * Upload a photo to Supabase Storage and insert a media_timeline record.
 * Path: {eventId}/{uploaderId}/{uuid}.{ext}
 */
export async function uploadEventPhoto(
  supabase: SupabaseClient<Database>,
  params: {
    eventId: string;
    uploaderId: string;
    file: File;
    width: number;
    height: number;
  },
): Promise<{ id: string; storagePath: string; publicUrl: string }> {
  const { eventId, uploaderId, file, width, height } = params;

  // Validate
  if (!ALLOWED_TYPES.has(file.type)) {
    throw new Error("JPG, PNG, WebP, HEIC 이미지만 업로드할 수 있어요");
  }
  if (file.size > MAX_FILE_SIZE) {
    throw new Error("10MB 이하의 이미지만 업로드할 수 있어요");
  }

  // Build unique path
  const ext = file.name.split(".").pop()?.toLowerCase() ?? "jpg";
  const uniqueId = crypto.randomUUID();
  const storagePath = `${eventId}/${uploaderId}/${uniqueId}.${ext}`;

  // Upload to Storage
  const { error: uploadError } = await supabase.storage
    .from(BUCKET)
    .upload(storagePath, file, {
      contentType: file.type,
      upsert: false,
    });

  if (uploadError) {
    throw new Error(`업로드 실패: ${uploadError.message}`);
  }

  // Get public URL (signed URL for private bucket)
  const { data: urlData } = await supabase.storage
    .from(BUCKET)
    .createSignedUrl(storagePath, 60 * 60 * 24 * 7); // 7 day signed URL

  const publicUrl = urlData?.signedUrl ?? "";

  // Insert media_timeline record
  const { data, error: insertError } = await supabase
    .from("media_timeline")
    .insert({
      event_id: eventId,
      uploader_id: uploaderId,
      storage_path: storagePath,
      thumbnail_path: storagePath, // same for MVP, could add transform later
      width,
      height,
    })
    .select("id")
    .single();

  if (insertError) {
    // Clean up uploaded file on DB insert failure
    await supabase.storage.from(BUCKET).remove([storagePath]);
    throw new Error(`기록 저장 실패: ${insertError.message}`);
  }

  return { id: data.id, storagePath, publicUrl };
}

/**
 * Get signed URLs for an array of storage paths.
 */
export async function getSignedMediaUrls(
  supabase: SupabaseClient<Database>,
  paths: string[],
  expiresIn = 60 * 60 * 24, // 24 hours
): Promise<Map<string, string>> {
  if (paths.length === 0) return new Map();

  const { data, error } = await supabase.storage
    .from(BUCKET)
    .createSignedUrls(paths, expiresIn);

  if (error || !data) return new Map();

  const urlMap = new Map<string, string>();
  for (const item of data) {
    if (item.signedUrl && item.path) {
      urlMap.set(item.path, item.signedUrl);
    }
  }
  return urlMap;
}

/**
 * Delete a media file from Storage and its media_timeline record.
 */
export async function deleteEventPhoto(
  supabase: SupabaseClient<Database>,
  mediaId: string,
  storagePath: string,
): Promise<void> {
  // Delete DB record first
  const { error: dbError } = await supabase
    .from("media_timeline")
    .delete()
    .eq("id", mediaId);

  if (dbError) {
    throw new Error(`삭제 실패: ${dbError.message}`);
  }

  // Delete from Storage
  await supabase.storage.from(BUCKET).remove([storagePath]);
}
