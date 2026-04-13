"use client";

import { useState, useEffect, useCallback, useMemo } from "react";
import type {
  DashboardGuest,
  AttendanceCounts,
  GuestResponseStatus,
} from "@/lib/types";
import type { Database } from "@/lib/database.types";
import { createClient } from "@/lib/supabase/client";
import { calcAttendanceCounts } from "@/lib/mock-dashboard";

type GuestStateRow = Database["public"]["Tables"]["guest_states"]["Row"];

/** Shape returned by the joined select query. */
interface GuestWithProfile {
  id: string;
  event_id: string;
  user_id: string;
  status: string;
  companion_count: number;
  fee_intention: string | null;
  responded_at: string;
  profiles: { display_name: string; avatar_url: string | null } | null;
}

/** Map a guest_states row + joined profile into DashboardGuest. */
function rowToGuest(
  row: GuestStateRow,
  profile: { display_name: string; avatar_url: string | null } | null,
): DashboardGuest {
  return {
    id: row.id,
    name: profile?.display_name ?? "게스트",
    avatar: profile?.avatar_url ?? null,
    status: row.status as GuestResponseStatus,
    companionCount: row.companion_count,
    feeIntention: row.fee_intention,
    respondedAt: row.responded_at,
  };
}

/**
 * Supabase Realtime subscription for guest_states.
 *
 * - Fetches initial guest list (joined with profiles) on mount.
 * - Subscribes to postgres_changes on guest_states filtered by event_id.
 * - Handles INSERT, UPDATE, and DELETE payloads in real time.
 * - Returns guests, attendance counts, and loading state.
 */
export function useRealtimeGuests(eventId: string) {
  const [guests, setGuests] = useState<DashboardGuest[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Fetch profile by user_id for newly inserted rows
  const fetchProfile = useCallback(
    async (userId: string) => {
      const supabase = createClient();
      const { data } = await supabase
        .from("profiles")
        .select("display_name, avatar_url")
        .eq("id", userId)
        .single();
      return data;
    },
    [],
  );

  useEffect(() => {
    const supabase = createClient();

    // ── 1. Initial fetch: guest_states joined with profiles ──
    async function fetchGuests() {
      const { data, error } = await supabase
        .from("guest_states")
        .select(
          `
          id,
          event_id,
          user_id,
          status,
          companion_count,
          fee_intention,
          responded_at,
          profiles:user_id ( display_name, avatar_url )
        `,
        )
        .eq("event_id", eventId)
        .order("responded_at", { ascending: true });

      if (error) {
        console.error("[useRealtimeGuests] fetch error:", error.message);
        setIsLoading(false);
        return;
      }

      const rows = (data ?? []) as unknown as GuestWithProfile[];
      const mapped: DashboardGuest[] = rows.map((row) =>
        rowToGuest(row as unknown as GuestStateRow, row.profiles),
      );

      setGuests(mapped);
      setIsLoading(false);
    }

    fetchGuests();

    // ── 2. Realtime subscription ──
    const channel = supabase
      .channel(`event:${eventId}:guests`)
      .on<GuestStateRow>(
        "postgres_changes",
        {
          event: "INSERT",
          schema: "public",
          table: "guest_states",
          filter: `event_id=eq.${eventId}`,
        },
        async (payload) => {
          const row = payload.new;
          const profile = await fetchProfile(row.user_id);
          const guest = rowToGuest(row, profile);
          setGuests((prev) => {
            // Prevent duplicates (race between initial fetch and INSERT event)
            if (prev.some((g) => g.id === guest.id)) return prev;
            return [...prev, guest];
          });
        },
      )
      .on<GuestStateRow>(
        "postgres_changes",
        {
          event: "UPDATE",
          schema: "public",
          table: "guest_states",
          filter: `event_id=eq.${eventId}`,
        },
        (payload) => {
          const row = payload.new;
          setGuests((prev) =>
            prev.map((g) =>
              g.id === row.id
                ? {
                    ...g,
                    status: row.status as GuestResponseStatus,
                    companionCount: row.companion_count,
                    feeIntention: row.fee_intention,
                    respondedAt: row.responded_at,
                  }
                : g,
            ),
          );
        },
      )
      .on<GuestStateRow>(
        "postgres_changes",
        {
          event: "DELETE",
          schema: "public",
          table: "guest_states",
          filter: `event_id=eq.${eventId}`,
        },
        (payload) => {
          const oldRow = payload.old as Partial<GuestStateRow>;
          if (oldRow.id) {
            setGuests((prev) => prev.filter((g) => g.id !== oldRow.id));
          }
        },
      )
      .subscribe((status) => {
        if (status === "CHANNEL_ERROR") {
          console.error(
            "[useRealtimeGuests] channel error for event:",
            eventId,
          );
        }
      });

    // ── 3. Cleanup ──
    return () => {
      supabase.removeChannel(channel);
    };
  }, [eventId, fetchProfile]);

  const counts: AttendanceCounts = useMemo(
    () => calcAttendanceCounts(guests),
    [guests],
  );

  return { guests, counts, isLoading };
}
