"use client";

import { useState, useCallback, useMemo } from "react";
import { Button } from "@/components/ui/button";
import { StepIndicator } from "./step-indicator";
import { MoodSelector } from "./mood-selector";
import { CoverPicker } from "./cover-picker";
import { EventDetailsForm } from "./event-details-form";
import { EventPreview } from "./event-preview";
import type { EventFormData, EventMood } from "@/lib/types";
import { INITIAL_EVENT_FORM } from "@/lib/types";
import { getMoodTemplate } from "@/lib/mood-templates";

const TOTAL_STEPS = 4;

export function CreateEventWizard() {
  const [step, setStep] = useState(0);
  const [form, setForm] = useState<EventFormData>(INITIAL_EVENT_FORM);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const mood = useMemo(
    () => (form.mood ? getMoodTemplate(form.mood) : undefined),
    [form.mood]
  );

  const updateForm = useCallback((partial: Partial<EventFormData>) => {
    setForm((prev) => ({ ...prev, ...partial }));
  }, []);

  const handleMoodSelect = useCallback(
    (moodId: EventMood) => {
      updateForm({ mood: moodId });
    },
    [updateForm]
  );

  const handleCoverChange = useCallback(
    (url: string, file: File | null) => {
      updateForm({ coverImage: url, coverFile: file });
    },
    [updateForm]
  );

  const canProceed = useMemo(() => {
    switch (step) {
      case 0:
        return form.mood !== null;
      case 1:
        return true; // cover is optional
      case 2:
        return form.title.trim() !== "" && form.datetime !== "";
      case 3:
        return true;
      default:
        return false;
    }
  }, [step, form.mood, form.title, form.datetime]);

  const handleNext = useCallback(() => {
    if (step < TOTAL_STEPS - 1) {
      setStep((s) => s + 1);
    }
  }, [step]);

  const handleBack = useCallback(() => {
    if (step > 0) {
      setStep((s) => s - 1);
    }
  }, [step]);

  const handleSubmit = useCallback(async () => {
    setIsSubmitting(true);
    try {
      // TODO: Submit to Supabase when backend lane is ready
      // For now, log the form data
      console.log("Event created:", form);
      // Will redirect to /event/[id] after creation
      alert("이벤트가 생성되었습니다! (백엔드 연동 대기 중)");
    } finally {
      setIsSubmitting(false);
    }
  }, [form]);

  return (
    <div className="flex min-h-dvh flex-col">
      {/* Header */}
      <header className="sticky top-0 z-10 border-b bg-background/80 backdrop-blur-sm">
        <div className="mx-auto flex h-14 max-w-lg items-center justify-between px-4 md:max-w-2xl xl:max-w-3xl">
          {step > 0 ? (
            <button
              type="button"
              onClick={handleBack}
              className="flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground transition-colors"
            >
              <ChevronLeftIcon />
              <span>이전</span>
            </button>
          ) : (
            <div />
          )}
          <span className="text-sm font-medium">이벤트 만들기</span>
          <div className="w-12" />
        </div>
      </header>

      {/* Step indicator */}
      <div className="mx-auto w-full max-w-lg px-4 pt-4 md:max-w-2xl xl:max-w-3xl">
        <StepIndicator current={step} total={TOTAL_STEPS} />
      </div>

      {/* Content */}
      <main className="mx-auto w-full max-w-lg flex-1 px-4 py-6 md:max-w-2xl md:py-8 xl:max-w-3xl">
        {step === 0 && (
          <MoodSelector selected={form.mood} onSelect={handleMoodSelect} />
        )}
        {step === 1 && mood && (
          <CoverPicker
            coverImage={form.coverImage}
            mood={mood}
            onCoverChange={handleCoverChange}
          />
        )}
        {step === 2 && (
          <EventDetailsForm data={form} onUpdate={updateForm} />
        )}
        {step === 3 && mood && (
          <EventPreview data={form} mood={mood} />
        )}
      </main>

      {/* Bottom action bar */}
      <div className="sticky bottom-0 border-t bg-background/80 backdrop-blur-sm">
        <div className="mx-auto flex h-20 max-w-lg items-center justify-end px-4 md:max-w-2xl xl:max-w-3xl">
          {step < TOTAL_STEPS - 1 ? (
            <Button
              size="lg"
              className="h-12 w-full rounded-xl text-base font-semibold sm:w-auto sm:px-10"
              disabled={!canProceed}
              onClick={handleNext}
              style={
                mood
                  ? {
                      backgroundColor: mood.colorTheme.primary,
                      color: "#fff",
                    }
                  : undefined
              }
            >
              다음
            </Button>
          ) : (
            <Button
              size="lg"
              className="h-12 w-full rounded-xl text-base font-semibold sm:w-auto sm:px-10"
              disabled={isSubmitting}
              onClick={handleSubmit}
              style={
                mood
                  ? {
                      backgroundColor: mood.colorTheme.primary,
                      color: "#fff",
                    }
                  : undefined
              }
            >
              {isSubmitting ? "생성 중..." : "이벤트 생성하기"}
            </Button>
          )}
        </div>
      </div>
    </div>
  );
}

function ChevronLeftIcon() {
  return (
    <svg
      width="20"
      height="20"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="m15 18-6-6 6-6" />
    </svg>
  );
}
