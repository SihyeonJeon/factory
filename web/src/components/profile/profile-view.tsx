"use client";

import { useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import Image from "next/image";
import { signOut } from "@/lib/auth";

interface ProfileData {
  id: string;
  displayName: string;
  avatarUrl: string | null;
  email: string | null;
  provider: string | null;
  createdAt: string;
}

interface ProfileViewProps {
  profile: ProfileData;
  eventCount: number;
  crewCount: number;
}

const PROVIDER_LABELS: Record<string, string> = {
  kakao: "카카오",
  apple: "Apple",
  email: "이메일",
};

export function ProfileView({ profile, eventCount, crewCount }: ProfileViewProps) {
  const router = useRouter();
  const [displayName, setDisplayName] = useState(profile.displayName);
  const [isEditing, setIsEditing] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [isLoggingOut, setIsLoggingOut] = useState(false);
  const [editValue, setEditValue] = useState(profile.displayName);
  const [error, setError] = useState<string | null>(null);

  const handleSave = useCallback(async () => {
    const trimmed = editValue.trim();
    if (!trimmed || trimmed.length > 30) {
      setError("이름은 1~30자로 입력해주세요");
      return;
    }

    setIsSaving(true);
    setError(null);

    try {
      const res = await fetch("/api/profile", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ displayName: trimmed }),
      });

      if (!res.ok) {
        const body = await res.json();
        setError(body.error ?? "저장에 실패했습니다");
        return;
      }

      setDisplayName(trimmed);
      setIsEditing(false);
    } catch {
      setError("네트워크 오류가 발생했습니다");
    } finally {
      setIsSaving(false);
    }
  }, [editValue]);

  const handleCancel = useCallback(() => {
    setEditValue(displayName);
    setIsEditing(false);
    setError(null);
  }, [displayName]);

  const handleLogout = useCallback(async () => {
    setIsLoggingOut(true);
    try {
      await signOut();
      router.push("/");
      router.refresh();
    } catch {
      setIsLoggingOut(false);
    }
  }, [router]);

  return (
    <div className="space-y-6">
      {/* Avatar + Name */}
      <section className="flex flex-col items-center gap-4 py-4">
        <div className="relative h-20 w-20 overflow-hidden rounded-full bg-gray-100">
          {profile.avatarUrl ? (
            <Image
              src={profile.avatarUrl}
              alt={displayName}
              fill
              className="object-cover"
              sizes="80px"
            />
          ) : (
            <div className="flex h-full w-full items-center justify-center text-2xl font-bold text-gray-400">
              {displayName.charAt(0)}
            </div>
          )}
        </div>

        {isEditing ? (
          <div className="flex w-full max-w-xs flex-col items-center gap-2">
            <input
              type="text"
              value={editValue}
              onChange={(e) => setEditValue(e.target.value)}
              maxLength={30}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-center text-lg font-semibold focus:border-gray-900 focus:outline-none focus:ring-1 focus:ring-gray-900"
              autoFocus
            />
            <div className="flex gap-2">
              <button
                onClick={handleCancel}
                className="rounded-lg px-4 py-2 text-sm font-medium text-gray-500 transition-colors hover:bg-gray-100"
                disabled={isSaving}
              >
                취소
              </button>
              <button
                onClick={handleSave}
                className="rounded-lg bg-gray-900 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-gray-800 disabled:opacity-50"
                disabled={isSaving}
              >
                {isSaving ? "저장 중..." : "저장"}
              </button>
            </div>
          </div>
        ) : (
          <div className="flex items-center gap-2">
            <h2 className="text-xl font-bold">{displayName}</h2>
            <button
              onClick={() => {
                setEditValue(displayName);
                setIsEditing(true);
              }}
              className="rounded-md p-1 text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600"
              aria-label="이름 수정"
            >
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
                aria-hidden="true"
              >
                <path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z" />
              </svg>
            </button>
          </div>
        )}

        {error && (
          <p role="alert" className="text-sm text-red-500">
            {error}
          </p>
        )}
      </section>

      {/* Stats */}
      <section className="grid grid-cols-2 gap-3">
        <Link
          href="/my"
          className="flex flex-col items-center gap-1 rounded-2xl border bg-white p-4 transition-colors hover:bg-gray-50"
        >
          <span className="text-2xl font-bold">{eventCount}</span>
          <span className="text-sm text-gray-500">내 이벤트</span>
        </Link>
        <Link
          href="/my#crews"
          className="flex flex-col items-center gap-1 rounded-2xl border bg-white p-4 transition-colors hover:bg-gray-50"
        >
          <span className="text-2xl font-bold">{crewCount}</span>
          <span className="text-sm text-gray-500">내 아크</span>
        </Link>
      </section>

      {/* Account info */}
      <section className="space-y-3">
        <h3 className="text-sm font-semibold text-gray-500">계정 정보</h3>
        <div className="rounded-2xl border bg-white">
          {profile.email && (
            <div className="flex items-center justify-between border-b px-4 py-3 last:border-b-0">
              <span className="text-sm text-gray-500">이메일</span>
              <span className="text-sm font-medium">{profile.email}</span>
            </div>
          )}
          {profile.provider && (
            <div className="flex items-center justify-between border-b px-4 py-3 last:border-b-0">
              <span className="text-sm text-gray-500">로그인 방법</span>
              <span className="text-sm font-medium">
                {PROVIDER_LABELS[profile.provider] ?? profile.provider}
              </span>
            </div>
          )}
          <div className="flex items-center justify-between px-4 py-3">
            <span className="text-sm text-gray-500">가입일</span>
            <span className="text-sm font-medium">
              {new Date(profile.createdAt).toLocaleDateString("ko-KR", {
                year: "numeric",
                month: "long",
                day: "numeric",
              })}
            </span>
          </div>
        </div>
      </section>

      {/* Logout */}
      <section>
        <button
          onClick={handleLogout}
          disabled={isLoggingOut}
          className="w-full rounded-2xl border border-red-200 bg-white px-4 py-3 text-sm font-semibold text-red-500 transition-colors hover:bg-red-50 disabled:opacity-50"
        >
          {isLoggingOut ? "로그아웃 중..." : "로그아웃"}
        </button>
      </section>
    </div>
  );
}
