"use client";

import { useState, useCallback } from "react";
import { useRouter } from "next/navigation";

const MAX_NAME = 50;
const MAX_DESC = 500;

export function CrewCreateForm() {
  const router = useRouter();
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = useCallback(
    async (e: React.FormEvent) => {
      e.preventDefault();
      setError(null);

      const trimmedName = name.trim();
      if (!trimmedName) {
        setError("아크 이름을 입력해주세요");
        return;
      }
      if (trimmedName.length > MAX_NAME) {
        setError(`아크 이름은 ${MAX_NAME}자 이하여야 합니다`);
        return;
      }

      setSubmitting(true);

      try {
        const res = await fetch("/api/crews", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            name: trimmedName,
            description: description.trim(),
          }),
        });

        const data = await res.json();

        if (!res.ok) {
          setError(data.error ?? "아크 생성에 실패했습니다");
          return;
        }

        router.push(`/crew/${data.id}`);
      } catch {
        setError("네트워크 오류가 발생했습니다");
      } finally {
        setSubmitting(false);
      }
    },
    [name, description, router],
  );

  return (
    <form onSubmit={handleSubmit} className="space-y-5">
      {/* Name */}
      <div>
        <label
          htmlFor="crew-name"
          className="mb-1.5 block text-sm font-medium text-gray-700"
        >
          아크 이름 <span className="text-red-500">*</span>
        </label>
        <input
          id="crew-name"
          type="text"
          value={name}
          onChange={(e) => setName(e.target.value)}
          maxLength={MAX_NAME}
          placeholder="예: 한강 러닝 아크"
          className="w-full rounded-xl border px-4 py-3 text-sm transition-colors focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary"
          required
          autoFocus
        />
        <p className="mt-1 text-right text-xs text-gray-400">
          {name.length}/{MAX_NAME}
        </p>
      </div>

      {/* Description */}
      <div>
        <label
          htmlFor="crew-desc"
          className="mb-1.5 block text-sm font-medium text-gray-700"
        >
          설명 <span className="text-xs text-gray-400">(선택)</span>
        </label>
        <textarea
          id="crew-desc"
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          maxLength={MAX_DESC}
          placeholder="아크에 대해 간단히 소개해주세요"
          rows={3}
          className="w-full resize-none rounded-xl border px-4 py-3 text-sm transition-colors focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary"
        />
        <p className="mt-1 text-right text-xs text-gray-400">
          {description.length}/{MAX_DESC}
        </p>
      </div>

      {/* Error */}
      {error && (
        <p className="rounded-lg bg-red-50 px-4 py-2.5 text-sm text-red-600" role="alert">
          {error}
        </p>
      )}

      {/* Submit */}
      <button
        type="submit"
        disabled={submitting || !name.trim()}
        className="flex h-12 w-full items-center justify-center rounded-xl bg-primary text-base font-semibold text-primary-foreground transition-colors hover:bg-primary/90 disabled:opacity-50"
      >
        {submitting ? "만드는 중..." : "아크 만들기"}
      </button>
    </form>
  );
}
