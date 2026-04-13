"use client";

import { useState, useCallback, useMemo } from "react";
import { Button } from "@/components/ui/button";
import { EventHero } from "./event-hero";
import { RsvpStatusSelector } from "./rsvp-status-selector";
import { RsvpDetailsForm } from "./rsvp-details-form";
import { RsvpConfirmation } from "./rsvp-confirmation";
import type { EventDetail, GuestRsvp, RsvpStatus } from "@/lib/types";
import { INITIAL_GUEST_RSVP } from "@/lib/types";
import { getMoodTemplate } from "@/lib/mood-templates";

type FlowPhase = "view" | "respond" | "confirmed";

interface EventRsvpFlowProps {
  event: EventDetail;
}

export function EventRsvpFlow({ event }: EventRsvpFlowProps) {
  const mood = useMemo(() => getMoodTemplate(event.mood), [event.mood]);
  const [phase, setPhase] = useState<FlowPhase>("view");
  const [rsvp, setRsvp] = useState<GuestRsvp>(INITIAL_GUEST_RSVP);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const updateRsvp = useCallback((partial: Partial<GuestRsvp>) => {
    setRsvp((prev) => ({ ...prev, ...partial }));
  }, []);

  const handleStatusSelect = useCallback(
    (status: RsvpStatus) => {
      updateRsvp({
        status,
        // Reset details when switching away from attending
        ...(status !== "attending"
          ? { companionCount: 0, feeIntention: null }
          : {}),
      });
    },
    [updateRsvp]
  );

  const handleSubmit = useCallback(async () => {
    setIsSubmitting(true);
    try {
      const res = await fetch("/api/rsvp", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          eventId: event.id,
          status: rsvp.status,
          companionCount: rsvp.companionCount,
          feeIntention: rsvp.feeIntention,
        }),
      });

      if (!res.ok) {
        const body = await res.json();
        alert(body.error ?? "응답 제출에 실패했습니다");
        return;
      }

      setPhase("confirmed");
    } catch {
      alert("네트워크 오류가 발생했습니다");
    } finally {
      setIsSubmitting(false);
    }
  }, [event.id, rsvp]);

  const handleReset = useCallback(() => {
    setPhase("respond");
  }, []);

  if (!mood) return null;

  return (
    <div className="flex min-h-dvh flex-col">
      {/* Header */}
      <header className="sticky top-0 z-10 border-b bg-background/80 backdrop-blur-sm">
        <div className="mx-auto flex h-14 max-w-lg items-center justify-center px-4 xl:max-w-6xl">
          <span className="text-sm font-medium">모먼트</span>
        </div>
      </header>

      {/* Content */}
      <main className="mx-auto w-full max-w-lg flex-1 px-4 py-6 md:py-8 xl:max-w-6xl xl:py-10">
        <div className="xl:grid xl:grid-cols-[1fr_400px] xl:gap-12">
          {/* Left column: event info */}
          <div className="space-y-8">
            {/* Event info — always visible */}
            <EventHero event={event} mood={mood} />

            {/* Photo timeline link */}
            <a
              href={`/event/${event.id}/photos`}
              className="flex items-center justify-between rounded-xl border p-4 transition-colors hover:bg-gray-50"
            >
              <div className="flex items-center gap-3">
                <span className="text-lg">📸</span>
                <div>
                  <p className="text-sm font-semibold">사진 타임라인</p>
                  <p className="text-xs text-gray-400">
                    모임의 순간을 함께 공유하세요
                  </p>
                </div>
              </div>
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
                className="text-gray-300"
              >
                <path d="m9 18 6-6-6-6" />
              </svg>
            </a>
          </div>

          {/* Right column (desktop) / below hero (mobile): RSVP area */}
          <div className="mt-8 space-y-8 xl:mt-0">
            {/* Divider — mobile only */}
            {phase !== "view" && (
              <div className="border-t xl:hidden" />
            )}

            {/* RSVP form */}
            {phase === "respond" && (
              <div className="space-y-6 xl:rounded-2xl xl:border xl:bg-white xl:p-6 xl:shadow-sm">
                <RsvpStatusSelector
                  selected={rsvp.status}
                  onSelect={handleStatusSelect}
                  mood={mood}
                />
                <RsvpDetailsForm
                  rsvp={rsvp}
                  onUpdate={updateRsvp}
                  mood={mood}
                  hasFee={event.hasFee}
                />
              </div>
            )}

            {/* Confirmation */}
            {phase === "confirmed" && (
              <RsvpConfirmation
                rsvp={rsvp}
                mood={mood}
                guestCount={
                  event.guestCount + (rsvp.status === "attending" ? 1 : 0)
                }
                onReset={handleReset}
              />
            )}
          </div>
        </div>
      </main>

      {/* Bottom action bar */}
      <div className="sticky bottom-0 border-t bg-background/80 backdrop-blur-sm">
        <div className="mx-auto flex h-20 max-w-lg items-center px-4 xl:max-w-6xl">
          {phase === "view" && (
            <Button
              size="lg"
              className="h-12 w-full rounded-xl text-base font-semibold"
              onClick={() => setPhase("respond")}
              style={{
                backgroundColor: mood.colorTheme.primary,
                color: "#fff",
              }}
            >
              참석 여부 응답하기
            </Button>
          )}

          {phase === "respond" && (
            <Button
              size="lg"
              className="h-12 w-full rounded-xl text-base font-semibold"
              disabled={isSubmitting}
              onClick={handleSubmit}
              style={{
                backgroundColor: mood.colorTheme.primary,
                color: "#fff",
              }}
            >
              {isSubmitting ? "제출 중..." : "응답 제출하기"}
            </Button>
          )}

          {phase === "confirmed" && (
            <div className="w-full text-center text-sm text-muted-foreground">
              카카오톡에서 이 링크를 공유하여 다른 분도 초대하세요
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
