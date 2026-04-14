"use client";

import { useState, useEffect, useCallback, useRef } from "react";
import type { EventComment } from "@/lib/types";
import type { Database } from "@/lib/database.types";
import { createClient } from "@/lib/supabase/client";

type CommentRow = Database["public"]["Tables"]["event_comments"]["Row"];

/** Shape returned by the joined select query. */
interface CommentWithProfile {
  id: string;
  event_id: string;
  author_id: string;
  body: string;
  created_at: string;
  profiles: { display_name: string; avatar_url: string | null } | null;
}

/** Map a comment row + joined profile into EventComment. */
function rowToComment(
  row: CommentRow,
  profile: { display_name: string; avatar_url: string | null } | null,
): EventComment {
  return {
    id: row.id,
    eventId: row.event_id,
    authorId: row.author_id,
    authorName: profile?.display_name ?? "게스트",
    authorAvatar: profile?.avatar_url ?? null,
    body: row.body,
    createdAt: row.created_at,
  };
}

/**
 * Supabase Realtime subscription for event_comments.
 *
 * - Fetches initial comment list (joined with profiles) on mount.
 * - Subscribes to postgres_changes on event_comments filtered by event_id.
 * - Handles INSERT and DELETE payloads in real time.
 * - Returns comments, and loading state.
 */
export function useRealtimeComments(eventId: string) {
  const [comments, setComments] = useState<EventComment[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Profile cache to avoid redundant fetches for the same user
  // Cleared when eventId changes to prevent unbounded growth
  const profileCache = useRef(
    new Map<string, { display_name: string; avatar_url: string | null }>(),
  );
  const prevEventId = useRef(eventId);
  if (prevEventId.current !== eventId) {
    profileCache.current.clear();
    prevEventId.current = eventId;
  }

  // Fetch profile by user_id for newly inserted rows (cached)
  const fetchProfile = useCallback(
    async (userId: string) => {
      const cached = profileCache.current.get(userId);
      if (cached) return cached;

      const supabase = createClient();
      const { data } = await supabase
        .from("profiles")
        .select("display_name, avatar_url")
        .eq("id", userId)
        .single();

      if (data) profileCache.current.set(userId, data);
      return data;
    },
    [],
  );

  useEffect(() => {
    const supabase = createClient();

    // ── 1. Initial fetch: event_comments joined with profiles ──
    async function fetchComments() {
      const { data, error } = await supabase
        .from("event_comments")
        .select(
          `
          id,
          event_id,
          author_id,
          body,
          created_at,
          profiles:author_id ( display_name, avatar_url )
        `,
        )
        .eq("event_id", eventId)
        .order("created_at", { ascending: true });

      if (error) {
        console.error("[useRealtimeComments] fetch error:", error.message);
        setIsLoading(false);
        return;
      }

      const rows = (data ?? []) as unknown as CommentWithProfile[];
      const mapped: EventComment[] = rows.map((row) =>
        rowToComment(row as unknown as CommentRow, row.profiles),
      );

      // Merge with any realtime INSERTs that arrived before this fetch resolved
      setComments((prev) => {
        if (prev.length === 0) return mapped;
        const mergedMap = new Map<string, EventComment>();
        for (const c of mapped) mergedMap.set(c.id, c);
        for (const c of prev) mergedMap.set(c.id, c); // realtime data wins
        return Array.from(mergedMap.values()).sort(
          (a, b) =>
            new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime(),
        );
      });
      setIsLoading(false);
    }

    fetchComments();

    // ── 2. Realtime subscription ──
    const channel = supabase
      .channel(`event:${eventId}:comments`)
      .on<CommentRow>(
        "postgres_changes",
        {
          event: "INSERT",
          schema: "public",
          table: "event_comments",
          filter: `event_id=eq.${eventId}`,
        },
        async (payload) => {
          const row = payload.new;
          const profile = await fetchProfile(row.author_id);
          const comment = rowToComment(row, profile);
          setComments((prev) => {
            // Prevent duplicates (race between initial fetch and INSERT event)
            if (prev.some((c) => c.id === comment.id)) return prev;
            return [...prev, comment];
          });
        },
      )
      .on<CommentRow>(
        "postgres_changes",
        {
          event: "DELETE",
          schema: "public",
          table: "event_comments",
          filter: `event_id=eq.${eventId}`,
        },
        (payload) => {
          const oldRow = payload.old as Partial<CommentRow>;
          if (oldRow.id) {
            setComments((prev) => prev.filter((c) => c.id !== oldRow.id));
          }
        },
      )
      .subscribe((status) => {
        if (status === "CHANNEL_ERROR") {
          console.error(
            "[useRealtimeComments] channel error for event:",
            eventId,
          );
        }
      });

    // ── 3. Cleanup ──
    return () => {
      supabase.removeChannel(channel);
    };
  }, [eventId, fetchProfile]);

  return { comments, isLoading };
}
