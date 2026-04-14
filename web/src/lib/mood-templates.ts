import type { MoodTemplate } from "./types";

export const MOOD_TEMPLATES: MoodTemplate[] = [
  {
    id: "birthday",
    label: "생일 파티",
    emoji: "🎂",
    colorTheme: {
      primary: "#D4366E",
      bg: "#FFF0F5",
      accent: "#B02058",
    },
    defaultCover: "/covers/birthday.svg",
  },
  {
    id: "running",
    label: "러닝 아크",
    emoji: "🏃",
    colorTheme: {
      primary: "#2BA69E",
      bg: "#F0FFFE",
      accent: "#1E8C85",
    },
    defaultCover: "/covers/running.svg",
  },
  {
    id: "wine",
    label: "와인 모임",
    emoji: "🍷",
    colorTheme: {
      primary: "#8B5CF6",
      bg: "#F5F0FF",
      accent: "#6D28D9",
    },
    defaultCover: "/covers/wine.svg",
  },
  {
    id: "book",
    label: "독서 모임",
    emoji: "📚",
    colorTheme: {
      primary: "#B87708",
      bg: "#FFFBF0",
      accent: "#92600A",
    },
    defaultCover: "/covers/book.svg",
  },
  {
    id: "houseparty",
    label: "하우스 파티",
    emoji: "🏠",
    colorTheme: {
      primary: "#BE185D",
      bg: "#FFF0F7",
      accent: "#9D174D",
    },
    defaultCover: "/covers/houseparty.svg",
  },
  {
    id: "salon",
    label: "브랜드 살롱",
    emoji: "✨",
    colorTheme: {
      primary: "#0369A1",
      bg: "#F0F9FF",
      accent: "#075985",
    },
    defaultCover: "/covers/salon.svg",
  },
];

export function getMoodTemplate(id: string): MoodTemplate | undefined {
  return MOOD_TEMPLATES.find((t) => t.id === id);
}
