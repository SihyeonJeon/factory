export type EventMood =
  | "birthday"
  | "running"
  | "wine"
  | "book"
  | "houseparty"
  | "salon";

export interface MoodTemplate {
  id: EventMood;
  label: string;
  emoji: string;
  colorTheme: {
    primary: string;
    bg: string;
    accent: string;
  };
  defaultCover: string;
}

export interface EventFormData {
  mood: EventMood | null;
  coverImage: string | null;
  coverFile: File | null;
  title: string;
  datetime: string;
  location: string;
  description: string;
}

export const INITIAL_EVENT_FORM: EventFormData = {
  mood: null,
  coverImage: null,
  coverFile: null,
  title: "",
  datetime: "",
  location: "",
  description: "",
};

// ── RSVP types ──

export type RsvpStatus = "attending" | "declined" | "maybe";

export interface GuestRsvp {
  status: RsvpStatus;
  companionCount: number;
  feeIntention: "will_pay" | "undecided" | null;
}

export const INITIAL_GUEST_RSVP: GuestRsvp = {
  status: "attending",
  companionCount: 0,
  feeIntention: null,
};

export const RSVP_STATUS_CONFIG: Record<
  RsvpStatus,
  { label: string; description: string }
> = {
  attending: { label: "참석", description: "참석할게요!" },
  declined: { label: "불참", description: "이번엔 어려워요" },
  maybe: { label: "미정", description: "아직 모르겠어요" },
};

// ── Event detail (read-only, for guest-facing page) ──

export interface EventDetail {
  id: string;
  title: string;
  datetime: string;
  location: string;
  description: string;
  mood: EventMood;
  coverImage: string | null;
  hostName: string;
  hostAvatar: string | null;
  guestCount: number;
  hasFee: boolean;
}

// ── Dashboard types ──

export type GuestResponseStatus = RsvpStatus | "pending";

export interface DashboardGuest {
  id: string;
  name: string;
  avatar: string | null;
  status: GuestResponseStatus;
  companionCount: number;
  feeIntention: "will_pay" | "undecided" | null;
  respondedAt: string | null;
}

export interface AttendanceCounts {
  attending: number;
  declined: number;
  maybe: number;
  pending: number;
  totalHeadcount: number; // attending + companions
}

// ── Photo timeline types ──

export interface TimelinePhoto {
  id: string;
  eventId: string;
  url: string;
  thumbnailUrl: string;
  uploaderName: string;
  uploaderAvatar: string | null;
  uploadedAt: string;
  width: number;
  height: number;
}
