"use client";

import { useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";

interface CrewJoinViewProps {
  crewId: string;
  name: string;
  description: string;
  memberCount: number;
  inviteCode: string;
  isLoggedIn: boolean;
  isMember: boolean;
}

export function CrewJoinView({
  crewId,
  name,
  description,
  memberCount,
  inviteCode,
  isLoggedIn,
  isMember,
}: CrewJoinViewProps) {
  const router = useRouter();
  const [joining, setJoining] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleJoin = useCallback(async () => {
    if (!isLoggedIn) {
      router.push(`/login?next=/crew/join/${inviteCode}`);
      return;
    }

    setJoining(true);
    setError(null);

    try {
      const res = await fetch("/api/crews/join", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ inviteCode }),
      });

      const data = await res.json();

      if (!res.ok) {
        setError(data.error ?? "참여에 실패했습니다");
        return;
      }

      router.push(`/crew/${data.crewId}`);
    } catch {
      setError("네트워크 오류가 발생했습니다");
    } finally {
      setJoining(false);
    }
  }, [isLoggedIn, inviteCode, router]);

  return (
    <div className="flex min-h-dvh flex-col items-center justify-center px-4">
      <div className="w-full max-w-sm space-y-6 text-center">
        {/* Crew icon */}
        <div className="mx-auto flex h-20 w-20 items-center justify-center rounded-2xl bg-primary/10 text-3xl">
          👥
        </div>

        <div>
          <h1 className="text-2xl font-bold">{name}</h1>
          {description && (
            <p className="mt-2 text-sm text-gray-500 leading-relaxed">
              {description}
            </p>
          )}
          <p className="mt-2 text-sm text-gray-400">
            멤버 {memberCount}명
          </p>
        </div>

        {error && (
          <p
            className="rounded-lg bg-red-50 px-4 py-2.5 text-sm text-red-600"
            role="alert"
          >
            {error}
          </p>
        )}

        {isMember ? (
          <div className="space-y-3">
            <p className="text-sm text-gray-500">이미 참여한 아크입니다</p>
            <Link
              href={`/crew/${crewId}`}
              className="inline-flex h-12 w-full items-center justify-center rounded-xl bg-primary text-base font-semibold text-primary-foreground transition-colors hover:bg-primary/90"
            >
              아크 보기
            </Link>
          </div>
        ) : (
          <button
            type="button"
            onClick={handleJoin}
            disabled={joining}
            className="flex h-12 w-full items-center justify-center rounded-xl bg-primary text-base font-semibold text-primary-foreground transition-colors hover:bg-primary/90 disabled:opacity-50"
          >
            {joining ? "참여 중..." : "참여하기"}
          </button>
        )}

        {!isLoggedIn && !isMember && (
          <p className="text-xs text-gray-400">
            참여하려면 로그인이 필요합니다
          </p>
        )}
      </div>
    </div>
  );
}
