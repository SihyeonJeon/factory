---

## Implementation Report: 모바일 퍼스트 반응형 레이아웃 (375/768/1280px)

### Changed Files

| File | Purpose |
|------|---------|
| `src/app/globals.css` | PWA safe-area inset utilities (`safe-top`/`safe-bottom`), 44px minimum touch target on `pointer: coarse` devices, `scrollbar-none` utility, smooth scroll |
| `src/app/layout.tsx` | `viewportFit: "cover"` for notched devices, `userScalable: true` (accessibility), safe-area classes on `<body>` |
| `src/app/page.tsx` | Hero text scales: `text-4xl` → `md:text-5xl` → `xl:text-6xl`, CTA button grows on tablet+ |
| `src/components/create/create-event-wizard.tsx` | Container widens: `max-w-lg` → `md:max-w-2xl` → `xl:max-w-3xl` for header, step indicator, content, and bottom bar |
| `src/components/create/mood-selector.tsx` | Grid: `grid-cols-2` → `md:grid-cols-3` → `xl:grid-cols-4` |
| `src/components/create/event-preview.tsx` | Preview card: `max-w-sm` → `md:max-w-md` |
| `src/components/rsvp/event-rsvp-flow.tsx` | Desktop (xl): two-column layout — event hero left, RSVP card right (`xl:grid-cols-[1fr_400px]`). Mobile: stacked as before |
| `src/components/rsvp/event-hero.tsx` | Title scales to `md:text-3xl` |
| `src/components/dashboard/dashboard-view.tsx` | Desktop (xl): two-column sidebar layout — sticky event info + summary left (`340px`), guest list right. Container widens to `xl:max-w-6xl` |
| `src/components/dashboard/attendance-summary.tsx` | Status grid: `grid-cols-2` → `md:grid-cols-4` (was always 4, now 2×2 on small mobile) |
| `src/components/dashboard/guest-list.tsx` | Cards: stacked on mobile → `md:grid-cols-2` grid on tablet+ |
| `src/components/photos/photos-page-view.tsx` | Container widens to `xl:max-w-5xl`, increased vertical padding on tablet+ |
| `src/components/photos/photo-timeline.tsx` | Photo grid: `grid-cols-2` → `md:grid-cols-3` → `xl:grid-cols-4` |

### Breakpoint Strategy

| Breakpoint | Width | Target |
|---|---|---|
| Default | 375px+ | Mobile-first base — single column, compact spacing, full-width buttons |
| `md:` | 768px+ | Tablet — wider containers, multi-column grids, increased padding |
| `xl:` | 1280px+ | Desktop — two-column page layouts (dashboard sidebar, RSVP side-by-side), 4-col photo grid |

### Remaining Dependencies

- **PWA service worker + install prompt** — next frontend subtask
- **카카오톡 인앱 브라우저 UX 핸들링** — next frontend subtask
