import { ImageResponse } from "next/og";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { getMoodTemplate } from "@/lib/mood-templates";

export const alt = "모먼트 이벤트";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

/**
 * Dynamic OG image for /event/[id].
 * Renders event title, date, location, and mood-based styling.
 * Uses Satori (via ImageResponse) — no external image service needed.
 */
export default async function OgImage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  // Fetch event from Supabase
  const supabase = await createServerSupabaseClient();
  const { data: event } = await supabase
    .from("events")
    .select("title, datetime, location, mood, cover_image_url, color_theme")
    .eq("id", id)
    .single();

  // Fallback if event not found
  const title = event?.title ?? "모먼트";
  const mood = event?.mood ?? "wine";
  const location = event?.location ?? "";
  const datetime = event?.datetime ?? "";

  const template = getMoodTemplate(mood);
  const primaryColor = event?.color_theme?.primary ?? template?.colorTheme.primary ?? "#8B5CF6";
  const bgColor = event?.color_theme?.bg ?? template?.colorTheme.bg ?? "#F5F0FF";
  const accentColor = event?.color_theme?.accent ?? template?.colorTheme.accent ?? "#6D28D9";
  const emoji = template?.emoji ?? "";

  // Format date for display
  let formattedDate = "";
  if (datetime) {
    try {
      const d = new Date(datetime);
      formattedDate = d.toLocaleDateString("ko-KR", {
        month: "long",
        day: "numeric",
        weekday: "short",
        hour: "2-digit",
        minute: "2-digit",
      });
    } catch {
      formattedDate = "";
    }
  }

  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          background: `linear-gradient(135deg, ${bgColor} 0%, white 50%, ${bgColor} 100%)`,
          position: "relative",
          overflow: "hidden",
        }}
      >
        {/* Decorative circles */}
        <div
          style={{
            position: "absolute",
            top: "-80px",
            right: "-80px",
            width: "320px",
            height: "320px",
            borderRadius: "50%",
            background: primaryColor,
            opacity: 0.1,
            display: "flex",
          }}
        />
        <div
          style={{
            position: "absolute",
            bottom: "-60px",
            left: "-60px",
            width: "240px",
            height: "240px",
            borderRadius: "50%",
            background: accentColor,
            opacity: 0.08,
            display: "flex",
          }}
        />

        {/* Content area */}
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            justifyContent: "center",
            padding: "60px 80px",
            flex: 1,
          }}
        >
          {/* Mood emoji badge */}
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: "12px",
              marginBottom: "24px",
            }}
          >
            <div
              style={{
                fontSize: "48px",
                display: "flex",
              }}
            >
              {emoji}
            </div>
            <div
              style={{
                fontSize: "20px",
                color: primaryColor,
                fontWeight: 600,
                letterSpacing: "-0.02em",
                display: "flex",
              }}
            >
              {template?.label ?? "모임"}
            </div>
          </div>

          {/* Title */}
          <div
            style={{
              fontSize: title.length > 20 ? "52px" : "64px",
              fontWeight: 700,
              color: "#1a1a1a",
              lineHeight: 1.2,
              letterSpacing: "-0.03em",
              marginBottom: "28px",
              display: "flex",
            }}
          >
            {title}
          </div>

          {/* Date & Location */}
          <div
            style={{
              display: "flex",
              flexDirection: "column",
              gap: "12px",
            }}
          >
            {formattedDate && (
              <div
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "8px",
                  fontSize: "24px",
                  color: "#555",
                }}
              >
                <span style={{ display: "flex" }}>📅</span>
                <span style={{ display: "flex" }}>{formattedDate}</span>
              </div>
            )}
            {location && (
              <div
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "8px",
                  fontSize: "24px",
                  color: "#555",
                }}
              >
                <span style={{ display: "flex" }}>📍</span>
                <span style={{ display: "flex" }}>{location}</span>
              </div>
            )}
          </div>
        </div>

        {/* Bottom bar with branding */}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            padding: "20px 80px",
            borderTop: `2px solid ${primaryColor}20`,
            background: `${primaryColor}08`,
          }}
        >
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: "10px",
            }}
          >
            <div
              style={{
                width: "32px",
                height: "32px",
                borderRadius: "8px",
                background: primaryColor,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: "white",
                fontSize: "18px",
                fontWeight: 700,
              }}
            >
              M
            </div>
            <div
              style={{
                fontSize: "20px",
                fontWeight: 600,
                color: "#333",
                display: "flex",
              }}
            >
              모먼트
            </div>
          </div>
          <div
            style={{
              fontSize: "16px",
              color: primaryColor,
              fontWeight: 500,
              display: "flex",
            }}
          >
            프라이빗 모임 운영 플랫폼
          </div>
        </div>
      </div>
    ),
    {
      ...size,
    },
  );
}
