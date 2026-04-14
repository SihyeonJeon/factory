"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

/** Pathnames where the bottom nav should be hidden */
const HIDDEN_PATHS = ["/login", "/create"];
const HIDDEN_PREFIXES = ["/event/"];

interface NavItem {
  href: string;
  label: string;
  icon: (active: boolean) => React.ReactNode;
}

function HomeIcon({ active }: { active: boolean }) {
  return (
    <svg
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill={active ? "currentColor" : "none"}
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="M3 9.5L12 3l9 6.5V20a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9.5z" />
      {!active && <path d="M9 21V12h6v9" />}
    </svg>
  );
}

function CalendarIcon({ active }: { active: boolean }) {
  return (
    <svg
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill={active ? "currentColor" : "none"}
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <rect x="3" y="4" width="18" height="18" rx="2" />
      <path d="M16 2v4M8 2v4M3 10h18" />
    </svg>
  );
}

function UsersIcon({ active }: { active: boolean }) {
  return (
    <svg
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill={active ? "currentColor" : "none"}
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
      <circle cx="9" cy="7" r="4" />
      <path d="M23 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75" />
    </svg>
  );
}

function PersonIcon({ active }: { active: boolean }) {
  return (
    <svg
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill={active ? "currentColor" : "none"}
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
      <circle cx="12" cy="7" r="4" />
    </svg>
  );
}

const NAV_ITEMS: NavItem[] = [
  {
    href: "/",
    label: "홈",
    icon: (active) => <HomeIcon active={active} />,
  },
  {
    href: "/my",
    label: "이벤트",
    icon: (active) => <CalendarIcon active={active} />,
  },
  {
    href: "/my#crews",
    label: "아크",
    icon: (active) => <UsersIcon active={active} />,
  },
  {
    href: "/profile",
    label: "프로필",
    icon: (active) => <PersonIcon active={active} />,
  },
];

function isActive(pathname: string, href: string): boolean {
  if (href === "/") return pathname === "/";
  if (href === "/my#crews") return false; // arcs tab never "active" by pathname alone
  if (href === "/my") return pathname === "/my";
  return pathname.startsWith(href);
}

export function BottomNav() {
  const pathname = usePathname();

  // Hide on specific pages
  if (HIDDEN_PATHS.includes(pathname)) return null;
  if (HIDDEN_PREFIXES.some((p) => pathname.startsWith(p))) return null;

  return (
    <nav
      className="fixed bottom-0 left-0 right-0 z-40 border-t border-gray-200 bg-white/80 backdrop-blur-md"
      style={{ paddingBottom: "env(safe-area-inset-bottom, 0px)" }}
      aria-label="메인 내비게이션"
    >
      <div className="mx-auto flex h-16 max-w-lg items-center justify-around">
        {NAV_ITEMS.map((item) => {
          const active = isActive(pathname, item.href);
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex flex-col items-center justify-center gap-0.5 px-3 py-1 transition-colors ${
                active ? "text-gray-900" : "text-gray-400"
              }`}
              aria-current={active ? "page" : undefined}
            >
              {item.icon(active)}
              <span className="text-[10px] font-medium leading-tight">
                {item.label}
              </span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
