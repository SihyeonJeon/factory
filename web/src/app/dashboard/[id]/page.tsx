import type { Metadata } from "next";
import { getMockEvent } from "@/lib/mock-event";
import { DashboardView } from "@/components/dashboard/dashboard-view";

type Props = {
  params: Promise<{ id: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const event = getMockEvent(id);
  return {
    title: `대시보드 — ${event.title} — 모먼트`,
    description: "호스트 대시보드: 참석 현황 및 게스트 관리",
  };
}

export default async function DashboardPage({ params }: Props) {
  const { id } = await params;
  const event = getMockEvent(id);

  return <DashboardView event={event} />;
}
