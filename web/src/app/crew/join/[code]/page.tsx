import type { Metadata } from "next";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { notFound } from "next/navigation";
import { CrewJoinView } from "./crew-join-view";

type Props = {
  params: Promise<{ code: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { code } = await params;
  const supabase = await createServerSupabaseClient();

  const { data } = await supabase.rpc("get_crew_preview", {
    p_invite_code: code,
  });

  const crew = data?.[0];
  if (!crew) return { title: "초대 — 모먼트" };

  return {
    title: `${crew.name} 아크 초대 — 모먼트`,
    description: `${crew.name} 아크에 참여하세요! 멤버 ${crew.member_count}명`,
    openGraph: {
      title: `${crew.name} 아크에 참여하세요!`,
      description: crew.description || `멤버 ${crew.member_count}명`,
      type: "website",
      siteName: "모먼트",
    },
  };
}

export default async function CrewJoinPage({ params }: Props) {
  const { code } = await params;
  const supabase = await createServerSupabaseClient();

  const { data } = await supabase.rpc("get_crew_preview", {
    p_invite_code: code,
  });

  const crew = data?.[0];
  if (!crew) notFound();

  // Check if user is logged in
  const {
    data: { user },
  } = await supabase.auth.getUser();

  // Check if already a member
  let isMember = false;
  if (user) {
    const { data: memberCheck } = await supabase.rpc("is_crew_member", {
      p_crew_id: crew.id,
      p_user_id: user.id,
    });
    isMember = !!memberCheck;
  }

  return (
    <CrewJoinView
      crewId={crew.id}
      name={crew.name}
      description={crew.description}
      memberCount={crew.member_count}
      inviteCode={code}
      isLoggedIn={!!user}
      isMember={isMember}
    />
  );
}
