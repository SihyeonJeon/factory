import type { Metadata } from "next";
import { notFound, redirect } from "next/navigation";
import Link from "next/link";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { getCrewById, getCrewMembers } from "@/lib/crew-queries";
import { CrewMemberList } from "./crew-member-list";

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

type Props = {
  params: Promise<{ id: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  if (!UUID_RE.test(id)) return { title: "멤버 — 모먼트" };

  const supabase = await createServerSupabaseClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) return { title: "멤버 — 모먼트" };

  const crew = await getCrewById(supabase, id, user.id);
  return {
    title: crew ? `${crew.name} 멤버 — 모먼트` : "멤버 — 모먼트",
    robots: { index: false },
  };
}

export default async function CrewMembersPage({ params }: Props) {
  const { id } = await params;
  if (!UUID_RE.test(id)) notFound();

  const supabase = await createServerSupabaseClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect(`/login?next=/crew/${id}/members`);

  const [crew, members] = await Promise.all([
    getCrewById(supabase, id, user.id),
    getCrewMembers(supabase, id),
  ]);

  if (!crew) notFound();

  return (
    <div className="mx-auto min-h-dvh w-full max-w-lg px-4 py-6 md:py-10">
      {/* Back link */}
      <Link
        href={`/crew/${crew.id}`}
        className="mb-4 inline-flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700"
      >
        <svg
          aria-hidden="true"
          width="16"
          height="16"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <path d="m15 18-6-6 6-6" />
        </svg>
        {crew.name}
      </Link>

      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold">멤버 ({members.length})</h1>
      </div>

      <CrewMemberList
        crewId={crew.id}
        members={members}
        isAdmin={crew.role === "admin"}
        inviteCode={crew.inviteCode}
        crewName={crew.name}
      />
    </div>
  );
}
