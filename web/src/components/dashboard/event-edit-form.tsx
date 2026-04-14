"use client";

import { useState, useCallback } from "react";
import type { EventDetail } from "@/lib/types";

interface EventEditFormProps {
  event: EventDetail;
  accentColor: string;
  onSaved: (updated: Partial<EventDetail>) => void;
}

export function EventEditForm({ event, accentColor, onSaved }: EventEditFormProps) {
  const [open, setOpen] = useState(false);
  const [title, setTitle] = useState(event.title);
  const [datetime, setDatetime] = useState(
    toLocalDatetimeString(event.datetime),
  );
  const [location, setLocation] = useState(event.location);
  const [description, setDescription] = useState(event.description);
  const [status, setStatus] = useState<"idle" | "saving" | "saved" | "error">("idle");
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const handleSave = useCallback(async () => {
    // Client-side datetime validation (R39-003)
    const parsedDate = new Date(datetime);
    if (isNaN(parsedDate.getTime())) {
      setErrorMsg("유효한 날짜/시간을 입력해주세요");
      return;
    }
    setErrorMsg(null);
    setStatus("saving");
    try {
      const res = await fetch(`/api/events/${event.id}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          title: title.trim(),
          datetime: parsedDate.toISOString(),
          location: location.trim(),
          description: description.trim(),
        }),
      });
      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        setErrorMsg(data.error ?? "수정에 실패했습니다");
        setStatus("error");
        return;
      }
      setStatus("saved");
      onSaved({
        title: title.trim(),
        datetime: new Date(datetime).toISOString(),
        location: location.trim(),
        description: description.trim(),
      });
      setTimeout(() => setOpen(false), 800);
    } catch {
      setStatus("error");
    }
  }, [event.id, title, datetime, location, description, onSaved]);

  if (!open) {
    return (
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="flex w-full items-center justify-between rounded-xl border p-4 transition-colors hover:bg-gray-50"
      >
        <div className="flex items-center gap-3">
          <span className="text-lg">✏️</span>
          <div className="text-left">
            <p className="text-sm font-semibold">이벤트 수정</p>
            <p className="text-xs text-gray-400">
              제목, 날짜, 장소, 설명을 변경합니다
            </p>
          </div>
        </div>
        <svg
          aria-hidden="true"
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
      </button>
    );
  }

  return (
    <div className="space-y-4 rounded-xl border p-4">
      <h3 className="text-sm font-semibold">이벤트 수정</h3>

      <div>
        <label htmlFor="edit-title" className="block text-xs font-medium text-gray-500 mb-1">
          제목
        </label>
        <input
          id="edit-title"
          type="text"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          maxLength={100}
          className="w-full rounded-lg border px-3 py-2 text-sm focus:outline-none focus:ring-2"
          style={{ "--tw-ring-color": accentColor } as React.CSSProperties}
        />
      </div>

      <div>
        <label htmlFor="edit-datetime" className="block text-xs font-medium text-gray-500 mb-1">
          날짜/시간
        </label>
        <input
          id="edit-datetime"
          type="datetime-local"
          value={datetime}
          onChange={(e) => setDatetime(e.target.value)}
          className="w-full rounded-lg border px-3 py-2 text-sm focus:outline-none focus:ring-2"
          style={{ "--tw-ring-color": accentColor } as React.CSSProperties}
        />
      </div>

      <div>
        <label htmlFor="edit-location" className="block text-xs font-medium text-gray-500 mb-1">
          장소
        </label>
        <input
          id="edit-location"
          type="text"
          value={location}
          onChange={(e) => setLocation(e.target.value)}
          maxLength={200}
          className="w-full rounded-lg border px-3 py-2 text-sm focus:outline-none focus:ring-2"
          style={{ "--tw-ring-color": accentColor } as React.CSSProperties}
        />
      </div>

      <div>
        <label htmlFor="edit-description" className="block text-xs font-medium text-gray-500 mb-1">
          설명
        </label>
        <textarea
          id="edit-description"
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          maxLength={2000}
          rows={3}
          className="w-full rounded-lg border px-3 py-2 text-sm focus:outline-none focus:ring-2 resize-none"
          style={{ "--tw-ring-color": accentColor } as React.CSSProperties}
        />
      </div>

      {errorMsg && (
        <p role="alert" className="text-xs text-red-600">{errorMsg}</p>
      )}

      <div className="flex gap-2">
        <button
          type="button"
          onClick={handleSave}
          disabled={status === "saving" || !title.trim()}
          className="flex-1 rounded-lg py-2.5 text-sm font-semibold text-white transition-colors disabled:opacity-50"
          style={{ backgroundColor: accentColor }}
        >
          {status === "saving" ? "저장 중..." : status === "saved" ? "저장 완료!" : "저장"}
        </button>
        <button
          type="button"
          onClick={() => setOpen(false)}
          className="rounded-lg border px-4 py-2.5 text-sm font-medium text-gray-600 transition-colors hover:bg-gray-50"
        >
          취소
        </button>
      </div>
    </div>
  );
}

/** Convert ISO string to datetime-local input value (YYYY-MM-DDTHH:mm) */
function toLocalDatetimeString(iso: string): string {
  const d = new Date(iso);
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}
