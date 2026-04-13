import type { Metadata } from "next";
import { CreateEventWizard } from "@/components/create/create-event-wizard";

export const metadata: Metadata = {
  title: "이벤트 만들기 — 모먼트",
  description: "60초 만에 감성 이벤트 페이지를 만들고 카카오톡으로 공유하세요.",
};

export default function CreatePage() {
  return <CreateEventWizard />;
}
