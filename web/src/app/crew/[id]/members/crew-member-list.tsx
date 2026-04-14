"use client";

import { useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import type { CrewMember } from "@/lib/types";
import { ShareButton } from "@/components/ui/share-button";

interface CrewMemberListProps {
  crewId: string;
  members: CrewMember[];
  isAdmin: boolean;
  inviteCode: string;
  crewName: string;
}

export function CrewMemberList({
  crewId,
  members,
  isAdmin,
  inviteCode,
  crewName,
}: CrewMemberListProps) {
  const router = useRouter();
  const [removingId, setRemovingId] = useState<string | null>(null);

  const handleRemove = useCallback(
    async (userId: string, name: string) => {
      if (!confirm(`${name}님을 아크에서 제거하시겠습니까?`)) return;

      setRemovingId(userId);
      try {
        const res = await fetch(
          `/api/crews/${crewId}/members/${userId}`,
          { method: "DELETE" },
        );

        if (!res.ok) {
          const data = await res.json();
          alert(data.error ?? "멤버 제거에 실패했습니다");
          return;
        }

        router.refresh();
      } catch {
        alert("네트워크 오류가 발생했습니다");
      } finally {
        setRemovingId(null);
      }
    },
    [crewId, router],
  );

  return (
    <div className="space-y-4">
      {/* Invite button */}
      <ShareButton
        title={`${crewName} - 모먼트 아크`}
        text={`${crewName} 아크에 참여하세요!`}
        url={`/crew/join/${inviteCode}`}
        className="w-full justify-center"
      />

      {/* Member list */}
      <div className="space-y-2">
        {members.map((member) => (
          <div
            key={member.id}
            className="flex items-center gap-3 rounded-xl border bg-white p-3"
          >
            {/* Avatar */}
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-gray-100 text-sm font-medium text-gray-500">
              {member.avatar ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  src={member.avatar}
                  alt=""
                  className="h-full w-full rounded-full object-cover"
                />
              ) : (
                member.name.charAt(0)
              )}
            </div>

            {/* Info */}
            <div className="min-w-0 flex-1">
              <div className="flex items-center gap-2">
                <span className="truncate text-sm font-medium">
                  {member.name}
                </span>
                <span
                  className={`shrink-0 rounded-full px-2 py-0.5 text-[11px] font-medium ${
                    member.role === "admin"
                      ? "bg-primary/10 text-primary"
                      : "bg-gray-100 text-gray-500"
                  }`}
                >
                  {member.role === "admin" ? "관리자" : "멤버"}
                </span>
              </div>
              <p className="text-xs text-gray-400">
                {new Date(member.joinedAt).toLocaleDateString("ko-KR", {
                  year: "numeric",
                  month: "long",
                  day: "numeric",
                })}
                {" 가입"}
              </p>
            </div>

            {/* Remove button (admin only, can't remove other admins) */}
            {isAdmin && member.role !== "admin" && (
              <button
                type="button"
                onClick={() => handleRemove(member.userId, member.name)}
                disabled={removingId === member.userId}
                className="shrink-0 rounded-lg px-3 py-1.5 text-xs font-medium text-red-500 transition-colors hover:bg-red-50 disabled:opacity-50"
                aria-label={`${member.name} 제거`}
              >
                {removingId === member.userId ? "..." : "제거"}
              </button>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
