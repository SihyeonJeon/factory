import type { DashboardGuest, AttendanceCounts } from "./types";

const MOCK_GUESTS: DashboardGuest[] = [
  {
    id: "g1",
    name: "수진",
    avatar: null,
    status: "attending",
    companionCount: 1,
    feeIntention: "will_pay",
    respondedAt: "2026-04-12T10:30:00+09:00",
  },
  {
    id: "g2",
    name: "현우",
    avatar: null,
    status: "attending",
    companionCount: 0,
    feeIntention: "will_pay",
    respondedAt: "2026-04-12T11:15:00+09:00",
  },
  {
    id: "g3",
    name: "지은",
    avatar: null,
    status: "attending",
    companionCount: 0,
    feeIntention: "undecided",
    respondedAt: "2026-04-12T12:00:00+09:00",
  },
  {
    id: "g4",
    name: "태현",
    avatar: null,
    status: "maybe",
    companionCount: 0,
    feeIntention: null,
    respondedAt: "2026-04-12T13:20:00+09:00",
  },
  {
    id: "g5",
    name: "유나",
    avatar: null,
    status: "declined",
    companionCount: 0,
    feeIntention: null,
    respondedAt: "2026-04-12T14:00:00+09:00",
  },
  {
    id: "g6",
    name: "민수",
    avatar: null,
    status: "pending",
    companionCount: 0,
    feeIntention: null,
    respondedAt: null,
  },
  {
    id: "g7",
    name: "서연",
    avatar: null,
    status: "attending",
    companionCount: 0,
    feeIntention: "will_pay",
    respondedAt: "2026-04-12T15:45:00+09:00",
  },
  {
    id: "g8",
    name: "준혁",
    avatar: null,
    status: "pending",
    companionCount: 0,
    feeIntention: null,
    respondedAt: null,
  },
];

export function getMockGuests(): DashboardGuest[] {
  return MOCK_GUESTS;
}

export function calcAttendanceCounts(
  guests: DashboardGuest[]
): AttendanceCounts {
  let attending = 0;
  let declined = 0;
  let maybe = 0;
  let pending = 0;
  let totalHeadcount = 0;

  for (const g of guests) {
    switch (g.status) {
      case "attending":
        attending++;
        totalHeadcount += 1 + g.companionCount;
        break;
      case "declined":
        declined++;
        break;
      case "maybe":
        maybe++;
        break;
      case "pending":
        pending++;
        break;
    }
  }

  return { attending, declined, maybe, pending, totalHeadcount };
}
