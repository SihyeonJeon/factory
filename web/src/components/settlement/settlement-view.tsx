"use client";

import { useState, useMemo, useCallback } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { getMoodTemplate } from "@/lib/mood-templates";
import type { EventDetail } from "@/lib/types";
import type { ParticipantStatus } from "@/lib/database.types";

interface Settlement {
  id: string;
  event_id: string;
  total_amount: number;
  per_person: number;
  participant_statuses: ParticipantStatus[];
  created_at: string;
}

interface SettlementViewProps {
  event: EventDetail;
  initialSettlement: Settlement | null;
}

export function SettlementView({ event, initialSettlement }: SettlementViewProps) {
  const mood = useMemo(() => getMoodTemplate(event.mood), [event.mood]);
  const [settlement, setSettlement] = useState<Settlement | null>(initialSettlement);
  const [totalAmount, setTotalAmount] = useState("");
  const [isCreating, setIsCreating] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [markError, setMarkError] = useState<string | null>(null);

  const handleCreate = useCallback(async () => {
    const amount = parseInt(totalAmount, 10);
    if (!amount || amount <= 0) {
      setError("유효한 금액을 입력해주세요");
      return;
    }

    setIsCreating(true);
    setError(null);

    try {
      const res = await fetch("/api/settlement", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          action: "create",
          eventId: event.id,
          totalAmount: amount,
        }),
      });

      if (!res.ok) {
        const body = await res.json();
        setError(body.error ?? "정산 생성에 실패했습니다");
        return;
      }

      const data = await res.json();
      setSettlement(data.settlement);
    } catch {
      setError("네트워크 오류가 발생했습니다");
    } finally {
      setIsCreating(false);
    }
  }, [totalAmount, event.id]);

  const handleMarkPaid = useCallback(async (userId: string) => {
    try {
      const res = await fetch("/api/settlement", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          action: "mark_paid",
          eventId: event.id,
          userId,
        }),
      });

      if (!res.ok) return;

      const data = await res.json();
      setSettlement((prev) =>
        prev
          ? { ...prev, participant_statuses: data.participant_statuses }
          : prev,
      );
    } catch {
      setMarkError("상태 변경에 실패했습니다");
    }
  }, [event.id]);

  if (!mood) return null;

  const paidCount = settlement?.participant_statuses.filter((p) => p.paid).length ?? 0;
  const totalParticipants = settlement?.participant_statuses.length ?? 0;

  return (
    <div className="flex min-h-dvh flex-col">
      {/* Header */}
      <header className="sticky top-0 z-10 border-b bg-background/80 backdrop-blur-sm">
        <div className="mx-auto flex h-14 max-w-lg items-center justify-between px-4">
          <a
            href={`/dashboard/${event.id}`}
            className="flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground transition-colors"
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <path d="m15 18-6-6 6-6" />
            </svg>
            <span>대시보드</span>
          </a>
          <span className="text-sm font-medium">정산</span>
          <div className="w-16" />
        </div>
      </header>

      <main className="mx-auto w-full max-w-lg flex-1 px-4 py-6">
        {/* Event info */}
        <div className="mb-6 space-y-1">
          <p className="text-xs font-medium" style={{ color: mood.colorTheme.primary }}>
            {mood.emoji} {mood.label}
          </p>
          <h1 className="text-xl font-bold">{event.title}</h1>
        </div>

        {!settlement ? (
          /* ── Create settlement form ── */
          <div className="space-y-6">
            <div className="rounded-2xl border bg-white p-6 shadow-sm space-y-4">
              <h2 className="text-base font-semibold">정산 시작하기</h2>
              <p className="text-sm text-gray-500">
                총 금액을 입력하면 참석자 수로 나눠 1/N 정산을 계산합니다.
              </p>

              <div className="space-y-2">
                <label htmlFor="total-amount" className="text-sm font-medium">
                  총 금액 (원)
                </label>
                <Input
                  id="total-amount"
                  type="number"
                  inputMode="numeric"
                  placeholder="예: 150000"
                  value={totalAmount}
                  onChange={(e) => setTotalAmount(e.target.value)}
                  className="h-12 rounded-xl text-base"
                />
              </div>

              {error && (
                <p className="text-sm text-red-600">{error}</p>
              )}

              <Button
                onClick={handleCreate}
                disabled={isCreating || !totalAmount}
                className="h-12 w-full rounded-xl text-base font-semibold"
                style={{
                  backgroundColor: mood.colorTheme.primary,
                  color: "#fff",
                }}
              >
                {isCreating ? "계산 중..." : "정산 생성하기"}
              </Button>
            </div>
          </div>
        ) : (
          /* ── Settlement result ── */
          <div className="space-y-6">
            {/* Summary card */}
            <div className="rounded-2xl border bg-white p-6 shadow-sm space-y-4">
              <div className="flex items-center justify-between">
                <h2 className="text-base font-semibold">정산 요약</h2>
                <span className="text-xs text-gray-400">
                  {paidCount}/{totalParticipants}명 완료
                </span>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="rounded-xl bg-gray-50 p-4 text-center">
                  <p className="text-xs text-gray-500">총 금액</p>
                  <p className="mt-1 text-lg font-bold">
                    {settlement.total_amount.toLocaleString("ko-KR")}원
                  </p>
                </div>
                <div
                  className="rounded-xl p-4 text-center"
                  style={{ backgroundColor: mood.colorTheme.bg }}
                >
                  <p className="text-xs text-gray-500">1인당</p>
                  <p
                    className="mt-1 text-lg font-bold"
                    style={{ color: mood.colorTheme.primary }}
                  >
                    {settlement.per_person.toLocaleString("ko-KR")}원
                  </p>
                </div>
              </div>

              {/* Deep links */}
              <div className="flex gap-3">
                <a
                  href={`supertoss://send?amount=${settlement.per_person}&msg=${encodeURIComponent(`${event.title} 정산`)}`}
                  rel="noopener noreferrer"
                  className="flex-1 flex items-center justify-center gap-2 rounded-xl border-2 px-4 py-3 text-sm font-semibold transition-colors hover:bg-blue-50"
                  style={{ borderColor: "#0064FF", color: "#0064FF" }}
                >
                  토스로 송금
                </a>
                <a
                  href={`kakaotalk://kakaopay/money/to/send?amount=${settlement.per_person}`}
                  rel="noopener noreferrer"
                  className="flex-1 flex items-center justify-center gap-2 rounded-xl border-2 px-4 py-3 text-sm font-semibold transition-colors hover:bg-yellow-50"
                  style={{ borderColor: "#FEE500", color: "#191919" }}
                >
                  카카오페이
                </a>
              </div>
            </div>

            {/* Participant list */}
            <div className="rounded-2xl border bg-white p-6 shadow-sm">
              <h2 className="mb-4 text-base font-semibold">참여자 현황</h2>
              {markError && (
                <p className="mb-3 text-sm text-red-500" role="alert">{markError}</p>
              )}
              <ul className="divide-y">
                {settlement.participant_statuses.map((p) => (
                  <li key={p.user_id} className="flex items-center justify-between py-3">
                    <div className="flex items-center gap-3">
                      <div
                        className="flex h-8 w-8 items-center justify-center rounded-full text-xs font-medium text-white"
                        style={{
                          backgroundColor: p.paid
                            ? mood.colorTheme.primary
                            : "#d1d5db",
                        }}
                      >
                        {p.display_name.charAt(0)}
                      </div>
                      <span className="text-sm font-medium">{p.display_name}</span>
                    </div>

                    {p.paid ? (
                      <span
                        className="rounded-full px-3 py-1 text-xs font-semibold"
                        style={{
                          backgroundColor: mood.colorTheme.bg,
                          color: mood.colorTheme.primary,
                        }}
                      >
                        완료
                      </span>
                    ) : (
                      <button
                        type="button"
                        onClick={() => {
                          if (window.confirm(`${p.display_name}님을 납부 완료로 변경할까요?`)) {
                            handleMarkPaid(p.user_id);
                          }
                        }}
                        className="min-h-[44px] min-w-[44px] rounded-full border px-3 py-1 text-xs font-semibold text-gray-500 transition-colors hover:border-gray-400 hover:text-gray-700"
                      >
                        미완료
                      </button>
                    )}
                  </li>
                ))}
              </ul>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
