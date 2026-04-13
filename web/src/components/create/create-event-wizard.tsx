"use client";

import { useState, useCallback, useMemo } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { StepIndicator } from "./step-indicator";
import { MoodSelector } from "./mood-selector";
import { CoverPicker } from "./cover-picker";
import { EventDetailsForm } from "./event-details-form";
import { EventPreview } from "./event-preview";
import type { EventFormData, EventMood } from "@/lib/types";
import { INITIAL_EVENT_FORM } from "@/lib/types";
import { getMoodTemplate } from "@/lib/mood-templates";
import { createClient } from "@/lib/supabase/client";

const TOTAL_STEPS = 4;

export function CreateEventWizard() {
  const router = useRouter();
  const [step, setStep] = useState(0);
  const [form, setForm] = useState<EventFormData>(INITIAL_EVENT_FORM);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);

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
    setSubmitError(null);
    try {
      let coverImageUrl: string | null = null;

      // Upload cover image if a file was selected
      if (form.coverFile) {
        const supabase = createClient();
        const ext = form.coverFile.name.split(".").pop()?.toLowerCase() ?? "jpg";
        const path = `covers/${crypto.randomUUID()}.${ext}`;
        const { error: uploadError } = await supabase.storage
          .from("event-media")
          .upload(path, form.coverFile, { contentType: form.coverFile.type });
        if (uploadError) {
          setSubmitError(`이미지 업로드 실패: ${uploadError.message}`);
          return;
        }
        const { data: urlData } = await supabase.storage
          .from("event-media")
          .createSignedUrl(path, 60 * 60 * 24 * 365);
        coverImageUrl = urlData?.signedUrl ?? null;
      } else if (form.coverImage) {
        // Default cover (SVG path or null)
        coverImageUrl = form.coverImage;
      }

      const res = await fetch("/api/events", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          mood: form.mood,
          title: form.title,
          datetime: form.datetime,
          location: form.location,
          description: form.description,
          coverImageUrl,
        }),
      });

      if (!res.ok) {
        const body = await res.json();
        setSubmitError(body.error ?? "이벤트 생성에 실패했습니다");
        return;
      }

      const { id } = await res.json();
      router.push(`/dashboard/${id}`);
    } catch {
      setSubmitError("네트워크 오류가 발생했습니다");
    } finally {
      setIsSubmitting(false);
    }
  }, [form, router]);

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

      {/* Error message */}
      {submitError && (
        <div className="mx-auto max-w-lg px-4 md:max-w-2xl xl:max-w-3xl">
          <p className="rounded-lg bg-red-50 px-4 py-2 text-sm text-red-600">
            {submitError}
          </p>
        </div>
      )}

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
      aria-hidden="true"
    >
      <path d="m15 18-6-6 6-6" />
    </svg>
  );
}
