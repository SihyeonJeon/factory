"use client";

import Link from "next/link";
import type { Crew } from "@/lib/types";
import { ShareButton } from "@/components/ui/share-button";

interface CrewHeaderProps {
  crew: Crew;
}

export function CrewHeader({ crew }: CrewHeaderProps) {
  return (
    <div className="space-y-4">
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0 flex-1">
          <h1 className="text-2xl font-bold">{crew.name}</h1>
          {crew.description && (
            <p className="mt-1 text-sm text-gray-500 leading-relaxed">
              {crew.description}
            </p>
          )}
        </div>
        {crew.role === "admin" && (
          <Link
            href={`/crew/${crew.id}/members`}
            className="shrink-0 rounded-lg border px-3 py-2 text-sm font-medium text-gray-600 transition-colors hover:bg-gray-50"
            aria-label="설정"
          >
            <SettingsIcon />
          </Link>
        )}
      </div>

      <div className="flex items-center gap-3">
        <Link
          href={`/crew/${crew.id}/members`}
          className="inline-flex items-center gap-1.5 text-sm text-gray-500 hover:text-gray-700"
        >
          <UsersIcon />
          멤버 {crew.memberCount}명
        </Link>
        <span className="text-gray-300">|</span>
        <span className="text-sm text-gray-500">
          이벤트 {crew.eventCount}개
        </span>
      </div>

      <ShareButton
        title={`${crew.name} - 모먼트 아크`}
        text={`${crew.name} 아크에 참여하세요!`}
        url={`/crew/join/${crew.inviteCode}`}
        className="w-full justify-center"
      />
    </div>
  );
}

function SettingsIcon() {
  return (
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
    >
      <path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z" />
      <circle cx="12" cy="12" r="3" />
    </svg>
  );
}

function UsersIcon() {
  return (
    <svg
      aria-hidden="true"
      width="14"
      height="14"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
      <circle cx="9" cy="7" r="4" />
      <path d="M22 21v-2a4 4 0 0 0-3-3.87" />
      <path d="M16 3.13a4 4 0 0 1 0 7.75" />
    </svg>
  );
}
