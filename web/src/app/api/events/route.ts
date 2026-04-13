import { NextResponse } from "next/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { getMoodTemplate } from "@/lib/mood-templates";
import type { EventMoodEnum } from "@/lib/database.types";

export async function POST(request: Request) {
  const supabase = await createServerSupabaseClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json();
  const { mood, title, datetime, location, description, coverImageUrl } =
    body as {
      mood: EventMoodEnum;
      title: string;
      datetime: string;
      location: string;
      description: string;
      coverImageUrl: string | null;
    };

  if (!title || !datetime) {
    return NextResponse.json(
      { error: "title and datetime are required" },
      { status: 400 },
    );
  }

  const template = getMoodTemplate(mood);
  const colorTheme = template?.colorTheme ?? {
    primary: "#8B5CF6",
    bg: "#F5F0FF",
    accent: "#6D28D9",
  };

  const { data, error } = await supabase
    .from("events")
    .insert({
      host_id: user.id,
      title,
      datetime,
      location: location || "",
      mood: mood || "wine",
      cover_image_url: coverImageUrl,
      color_theme: colorTheme,
      description: description || "",
      has_fee: false,
    })
    .select("id")
    .single();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ id: data.id });
}
