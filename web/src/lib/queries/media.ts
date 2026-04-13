import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "../database.types";
import type { TimelinePhoto } from "../types";

/**
 * Fetch photos for an event from media_timeline + profiles,
 * resolving signed URLs from Supabase Storage.
 */
export async function getEventPhotos(
  supabase: SupabaseClient<Database>,
  eventId: string,
): Promise<TimelinePhoto[]> {
  const { data: rows, error } = await supabase
    .from("media_timeline")
    .select(
      `
      id,
      event_id,
      storage_path,
      thumbnail_path,
      width,
      height,
      uploaded_at,
      uploader:profiles!media_timeline_uploader_id_fkey (
        display_name,
        avatar_url
      )
    `,
    )
    .eq("event_id", eventId)
    .order("uploaded_at", { ascending: true });

  if (error || !rows || rows.length === 0) return [];

  // Batch-sign all storage paths
  const storagePaths = rows.map((r) => r.storage_path);
  const thumbnailPaths = rows
    .map((r) => r.thumbnail_path)
    .filter((p): p is string => p !== null);

  const allPaths = [...new Set([...storagePaths, ...thumbnailPaths])];

  const { data: signedData } = await supabase.storage
    .from("event-media")
    .createSignedUrls(allPaths, 60 * 60 * 24); // 24h

  const urlMap = new Map<string, string>();
  if (signedData) {
    for (const item of signedData) {
      if (item.signedUrl && item.path) {
        urlMap.set(item.path, item.signedUrl);
      }
    }
  }

  return rows.map((row) => {
    const uploader = row.uploader as
      | { display_name: string; avatar_url: string | null }
      | null;

    return {
      id: row.id,
      eventId: row.event_id,
      url: urlMap.get(row.storage_path) ?? "",
      thumbnailUrl: urlMap.get(row.thumbnail_path ?? row.storage_path) ?? "",
      uploaderName: uploader?.display_name ?? "",
      uploaderAvatar: uploader?.avatar_url ?? null,
      uploadedAt: row.uploaded_at,
      width: row.width ?? 800,
      height: row.height ?? 800,
    };
  });
}
