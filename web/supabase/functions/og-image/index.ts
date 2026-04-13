/**
 * og-image Edge Function (Satori fallback)
 *
 * Standalone OG image generator for events. Serves as a fallback when
 * Next.js opengraph-image route is unavailable (e.g., external crawlers
 * hitting Supabase directly, or for use in push notification thumbnails).
 *
 * Usage:
 *   GET /og-image?event_id=<uuid>
 *
 * Returns: PNG image (1200×630)
 *
 * Required env:
 *   - SUPABASE_URL
 *   - SUPABASE_SERVICE_ROLE_KEY
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.103.0";
import satori from "https://esm.sh/satori@0.12.1";
import { Resvg } from "https://esm.sh/@aspect-dev/resvg-js-deno-wasm@0.1.10";

interface ColorTheme {
  primary: string;
  bg: string;
  accent: string;
}

interface EventRow {
  title: string;
  datetime: string;
  location: string;
  mood: string;
  cover_image_url: string | null;
  color_theme: ColorTheme;
}

const MOOD_CONFIG: Record<string, { emoji: string; label: string; colors: ColorTheme }> = {
  birthday: {
    emoji: "\u{1F382}",
    label: "\uC0DD\uC77C \uD30C\uD2F0",
    colors: { primary: "#FF6B9D", bg: "#FFF0F5", accent: "#FF2D78" },
  },
  running: {
    emoji: "\u{1F3C3}",
    label: "\uB7EC\uB2DD \uD06C\uB8E8",
    colors: { primary: "#4ECDC4", bg: "#F0FFFE", accent: "#2AB7AD" },
  },
  wine: {
    emoji: "\u{1F377}",
    label: "\uC640\uC778 \uBAA8\uC784",
    colors: { primary: "#8B5CF6", bg: "#F5F0FF", accent: "#6D28D9" },
  },
  book: {
    emoji: "\u{1F4DA}",
    label: "\uB3C5\uC11C \uBAA8\uC784",
    colors: { primary: "#F59E0B", bg: "#FFFBF0", accent: "#D97706" },
  },
  houseparty: {
    emoji: "\u{1F3E0}",
    label: "\uD558\uC6B0\uC2A4 \uD30C\uD2F0",
    colors: { primary: "#EC4899", bg: "#FFF0F7", accent: "#DB2777" },
  },
  salon: {
    emoji: "\u2728",
    label: "\uBE0C\uB79C\uB4DC \uC0B4\uB871",
    colors: { primary: "#0EA5E9", bg: "#F0F9FF", accent: "#0284C7" },
  },
};

function formatDate(datetime: string): string {
  try {
    const d = new Date(datetime);
    return d.toLocaleDateString("ko-KR", {
      month: "long",
      day: "numeric",
      weekday: "short",
      hour: "2-digit",
      minute: "2-digit",
    });
  } catch {
    return "";
  }
}

/**
 * Build Satori-compatible JSX tree for the OG card.
 * Satori only supports a subset of CSS (flexbox, no grid).
 */
function buildOgMarkup(event: EventRow) {
  const mood = MOOD_CONFIG[event.mood] ?? MOOD_CONFIG.wine;
  const primary = event.color_theme?.primary ?? mood.colors.primary;
  const bg = event.color_theme?.bg ?? mood.colors.bg;
  const accent = event.color_theme?.accent ?? mood.colors.accent;
  const formattedDate = formatDate(event.datetime);
  const titleSize = event.title.length > 20 ? 52 : 64;

  return {
    type: "div",
    props: {
      style: {
        width: "100%",
        height: "100%",
        display: "flex",
        flexDirection: "column",
        background: `linear-gradient(135deg, ${bg} 0%, white 50%, ${bg} 100%)`,
        position: "relative",
        overflow: "hidden",
      },
      children: [
        // Content area
        {
          type: "div",
          props: {
            style: {
              display: "flex",
              flexDirection: "column",
              justifyContent: "center",
              padding: "60px 80px",
              flex: 1,
            },
            children: [
              // Mood badge
              {
                type: "div",
                props: {
                  style: {
                    display: "flex",
                    alignItems: "center",
                    gap: "12px",
                    marginBottom: "24px",
                  },
                  children: [
                    {
                      type: "div",
                      props: {
                        style: { fontSize: "48px", display: "flex" },
                        children: mood.emoji,
                      },
                    },
                    {
                      type: "div",
                      props: {
                        style: {
                          fontSize: "20px",
                          color: primary,
                          fontWeight: 600,
                          display: "flex",
                        },
                        children: mood.label,
                      },
                    },
                  ],
                },
              },
              // Title
              {
                type: "div",
                props: {
                  style: {
                    fontSize: `${titleSize}px`,
                    fontWeight: 700,
                    color: "#1a1a1a",
                    lineHeight: 1.2,
                    letterSpacing: "-0.03em",
                    marginBottom: "28px",
                    display: "flex",
                  },
                  children: event.title,
                },
              },
              // Date & Location
              {
                type: "div",
                props: {
                  style: {
                    display: "flex",
                    flexDirection: "column",
                    gap: "12px",
                  },
                  children: [
                    formattedDate
                      ? {
                          type: "div",
                          props: {
                            style: {
                              display: "flex",
                              alignItems: "center",
                              gap: "8px",
                              fontSize: "24px",
                              color: "#555",
                            },
                            children: `\u{1F4C5} ${formattedDate}`,
                          },
                        }
                      : null,
                    event.location
                      ? {
                          type: "div",
                          props: {
                            style: {
                              display: "flex",
                              alignItems: "center",
                              gap: "8px",
                              fontSize: "24px",
                              color: "#555",
                            },
                            children: `\u{1F4CD} ${event.location}`,
                          },
                        }
                      : null,
                  ].filter(Boolean),
                },
              },
            ],
          },
        },
        // Bottom branding bar
        {
          type: "div",
          props: {
            style: {
              display: "flex",
              alignItems: "center",
              justifyContent: "space-between",
              padding: "20px 80px",
              borderTop: `2px solid ${primary}20`,
              background: `${primary}08`,
            },
            children: [
              {
                type: "div",
                props: {
                  style: {
                    display: "flex",
                    alignItems: "center",
                    gap: "10px",
                  },
                  children: [
                    {
                      type: "div",
                      props: {
                        style: {
                          width: "32px",
                          height: "32px",
                          borderRadius: "8px",
                          background: primary,
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          color: "white",
                          fontSize: "18px",
                          fontWeight: 700,
                        },
                        children: "M",
                      },
                    },
                    {
                      type: "div",
                      props: {
                        style: {
                          fontSize: "20px",
                          fontWeight: 600,
                          color: "#333",
                          display: "flex",
                        },
                        children: "\uBAA8\uBA3C\uD2B8",
                      },
                    },
                  ],
                },
              },
              {
                type: "div",
                props: {
                  style: {
                    fontSize: "16px",
                    color: primary,
                    fontWeight: 500,
                    display: "flex",
                  },
                  children: "\uD504\uB77C\uC774\uBE57 \uBAA8\uC784 \uC6B4\uC601 \uD50C\uB7AB\uD3FC",
                },
              },
            ],
          },
        },
      ],
    },
  };
}

Deno.serve(async (req) => {
  if (req.method !== "GET") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  const url = new URL(req.url);
  const eventId = url.searchParams.get("event_id");

  if (!eventId) {
    return new Response(JSON.stringify({ error: "event_id is required" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient(supabaseUrl, serviceRoleKey);

  const { data: event, error } = await supabase
    .from("events")
    .select("title, datetime, location, mood, cover_image_url, color_theme")
    .eq("id", eventId)
    .single();

  if (error || !event) {
    return new Response(JSON.stringify({ error: "Event not found" }), {
      status: 404,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    // Fetch a default font for Satori (Noto Sans KR from Google Fonts)
    const fontResponse = await fetch(
      "https://fonts.gstatic.com/s/notosanskr/v36/PbyxFmXiEBPT4ITbgNA5Cgms3VYcOA-vvnIzzuozeLTq.ttf",
    );
    const fontData = await fontResponse.arrayBuffer();

    // Generate SVG with Satori
    const svg = await satori(buildOgMarkup(event as EventRow), {
      width: 1200,
      height: 630,
      fonts: [
        {
          name: "Noto Sans KR",
          data: fontData,
          weight: 700,
          style: "normal" as const,
        },
      ],
    });

    // Convert SVG → PNG with Resvg
    const resvg = new Resvg(svg, {
      fitTo: { mode: "width" as const, value: 1200 },
    });
    const pngData = resvg.render();
    const pngBuffer = pngData.asPng();

    return new Response(pngBuffer, {
      status: 200,
      headers: {
        "Content-Type": "image/png",
        "Cache-Control": "public, max-age=3600, s-maxage=86400",
      },
    });
  } catch (renderError) {
    console.error("OG image render failed:", renderError);
    return new Response(JSON.stringify({ error: "Failed to render OG image" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
