import type { DashboardGuest, AttendanceCounts } from "./types";

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
