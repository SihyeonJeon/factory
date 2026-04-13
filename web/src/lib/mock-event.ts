import type { EventDetail } from "./types";

/**
 * Mock event data for frontend development.
 * Will be replaced by Supabase queries when backend lane delivers.
 */
export function getMockEvent(id: string): EventDetail {
  return {
    id,
    title: "금요 와인 모임",
    datetime: "2026-04-18T19:00:00+09:00",
    location: "서울 성수동 르바 와인바",
    description:
      "이번 달 와인 모임입니다. 이탈리안 내추럴 와인 3종을 준비했어요. 가벼운 안주도 함께할 예정이니 편하게 오세요!",
    mood: "wine",
    coverImage: null,
    hostName: "민지",
    hostAvatar: null,
    guestCount: 6,
    hasFee: true,
  };
}
