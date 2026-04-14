import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { CrewCreateForm } from "./crew-create-form";

export const metadata: Metadata = {
  title: "아크 만들기 — 모먼트",
  robots: { index: false },
};

export default async function CrewCreatePage() {
  const supabase = await createServerSupabaseClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect("/login?next=/crew/create");

  return (
    <div className="mx-auto min-h-dvh w-full max-w-lg px-4 py-6 md:py-10">
      <h1 className="mb-6 text-2xl font-bold">아크 만들기</h1>
      <CrewCreateForm />
    </div>
  );
}
