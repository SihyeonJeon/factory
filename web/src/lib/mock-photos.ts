import type { TimelinePhoto } from "./types";

/**
 * Mock photo data for frontend development.
 * Uses picsum.photos placeholders — will be replaced by Supabase Storage URLs.
 */
const MOCK_PHOTOS: TimelinePhoto[] = [
  {
    id: "p1",
    eventId: "demo",
    url: "https://picsum.photos/seed/moment1/800/1200",
    thumbnailUrl: "https://picsum.photos/seed/moment1/400/600",
    uploaderName: "수진",
    uploaderAvatar: null,
    uploadedAt: "2026-04-18T19:30:00+09:00",
    width: 800,
    height: 1200,
  },
  {
    id: "p2",
    eventId: "demo",
    url: "https://picsum.photos/seed/moment2/1200/800",
    thumbnailUrl: "https://picsum.photos/seed/moment2/600/400",
    uploaderName: "현우",
    uploaderAvatar: null,
    uploadedAt: "2026-04-18T19:45:00+09:00",
    width: 1200,
    height: 800,
  },
  {
    id: "p3",
    eventId: "demo",
    url: "https://picsum.photos/seed/moment3/800/800",
    thumbnailUrl: "https://picsum.photos/seed/moment3/400/400",
    uploaderName: "지은",
    uploaderAvatar: null,
    uploadedAt: "2026-04-18T20:00:00+09:00",
    width: 800,
    height: 800,
  },
  {
    id: "p4",
    eventId: "demo",
    url: "https://picsum.photos/seed/moment4/800/1100",
    thumbnailUrl: "https://picsum.photos/seed/moment4/400/550",
    uploaderName: "수진",
    uploaderAvatar: null,
    uploadedAt: "2026-04-18T20:15:00+09:00",
    width: 800,
    height: 1100,
  },
  {
    id: "p5",
    eventId: "demo",
    url: "https://picsum.photos/seed/moment5/1200/900",
    thumbnailUrl: "https://picsum.photos/seed/moment5/600/450",
    uploaderName: "서연",
    uploaderAvatar: null,
    uploadedAt: "2026-04-18T20:30:00+09:00",
    width: 1200,
    height: 900,
  },
  {
    id: "p6",
    eventId: "demo",
    url: "https://picsum.photos/seed/moment6/900/1200",
    thumbnailUrl: "https://picsum.photos/seed/moment6/450/600",
    uploaderName: "태현",
    uploaderAvatar: null,
    uploadedAt: "2026-04-18T20:45:00+09:00",
    width: 900,
    height: 1200,
  },
  {
    id: "p7",
    eventId: "demo",
    url: "https://picsum.photos/seed/moment7/1000/800",
    thumbnailUrl: "https://picsum.photos/seed/moment7/500/400",
    uploaderName: "현우",
    uploaderAvatar: null,
    uploadedAt: "2026-04-18T21:00:00+09:00",
    width: 1000,
    height: 800,
  },
  {
    id: "p8",
    eventId: "demo",
    url: "https://picsum.photos/seed/moment8/800/1000",
    thumbnailUrl: "https://picsum.photos/seed/moment8/400/500",
    uploaderName: "민수",
    uploaderAvatar: null,
    uploadedAt: "2026-04-18T21:15:00+09:00",
    width: 800,
    height: 1000,
  },
];

export function getMockPhotos(eventId: string): TimelinePhoto[] {
  return MOCK_PHOTOS.map((p) => ({ ...p, eventId }));
}
