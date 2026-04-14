import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { ProfileView } from "@/components/profile/profile-view";

export const metadata: Metadata = {
  title: "프로필 -- 모먼트",
  robots: { index: false },
};

export default async function ProfilePage() {
  const supabase = await createServerSupabaseClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect("/login?next=/profile");

  // Fetch profile from profiles table
  const { data: profile } = await supabase
    .from("profiles")
    .select("id, display_name, avatar_url, created_at")
    .eq("id", user.id)
    .single();

  // Count events and crews
  const [eventsResult, crewsResult] = await Promise.all([
    supabase
      .from("guest_states")
      .select("id", { count: "exact", head: true })
      .eq("user_id", user.id),
    supabase
      .from("crew_members")
      .select("id", { count: "exact", head: true })
      .eq("user_id", user.id),
  ]);

  // Also count hosted events
  const { count: hostedCount } = await supabase
    .from("events")
    .select("id", { count: "exact", head: true })
    .eq("host_id", user.id);

  const eventCount = (eventsResult.count ?? 0) + (hostedCount ?? 0);
  const crewCount = crewsResult.count ?? 0;

  return (
    <div className="flex min-h-dvh flex-col pb-20">
      <header className="sticky top-0 z-10 border-b bg-background/80 backdrop-blur-sm">
        <div className="mx-auto flex h-14 max-w-lg items-center justify-center px-4">
          <span className="text-sm font-medium">프로필</span>
        </div>
      </header>
      <main className="mx-auto w-full max-w-lg flex-1 px-4 py-6">
        <ProfileView
          profile={{
            id: profile?.id ?? user.id,
            displayName: profile?.display_name ?? user.user_metadata?.full_name ?? "사용자",
            avatarUrl: profile?.avatar_url ?? user.user_metadata?.avatar_url ?? null,
            email: user.email ?? null,
            provider: user.app_metadata?.provider ?? null,
            createdAt: profile?.created_at ?? user.created_at,
          }}
          eventCount={eventCount}
          crewCount={crewCount}
        />
      </main>
    </div>
  );
}
