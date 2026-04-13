---

## Implementation Report: 이벤트 생성 위저드 UI

### Changed / Created Files

| File | Purpose |
|------|---------|
| `web/` | Next.js 16 project scaffold (App Router, TypeScript strict, Tailwind 4, shadcn/ui) |
| `src/app/layout.tsx` | Root layout — Noto Sans KR font, `lang="ko"`, PWA manifest link, viewport meta |
| `src/app/page.tsx` | Landing page with "이벤트 만들기" CTA → `/create` |
| `src/app/create/page.tsx` | `/create` route, renders `CreateEventWizard` |
| `src/app/globals.css` | shadcn/ui theme tokens (neutral base) |
| `src/lib/types.ts` | `EventMood`, `MoodTemplate`, `EventFormData` types + `INITIAL_EVENT_FORM` |
| `src/lib/mood-templates.ts` | 6 mood templates (생일/러닝/와인/독서/하우스파티/살롱) with color themes |
| `src/components/create/create-event-wizard.tsx` | 4-step wizard container — state management, step navigation, validation |
| `src/components/create/step-indicator.tsx` | Visual progress indicator (무드→커버→정보→미리보기) |
| `src/components/create/mood-selector.tsx` | Step 1: 6-card mood template grid with color-coded selection |
| `src/components/create/cover-picker.tsx` | Step 2: Gallery upload or default image, 16:9 preview |
| `src/components/create/event-details-form.tsx` | Step 3: Title, datetime, location, description inputs |
| `src/components/create/event-preview.tsx` | Step 4: Card preview mimicking the final event page (OG-card style) |
| `public/manifest.json` | PWA manifest (standalone, portrait, Korean) |

### Wizard Flow (60-second target)

1. **무드 선택** — 6 mood templates in a 2×3 grid, color-coded with emoji. One tap to select, button enables.
2. **커버 이미지** — Gallery file picker or default mood image. 16:9 preview. Optional step (can skip).
3. **모임 정보** — Title (required), datetime (required), location, description. Auto-focus on title.
4. **미리보기** — Full event card preview with mood badge, RSVP button mockup, formatted date in Korean.

### Key Design Decisions

- **Mobile-first**: `max-w-lg` container, sticky header/footer, `min-h-dvh`, touch-friendly 44px+ targets
- **Mood-driven theming**: Selected mood's `colorTheme.primary` dynamically colors the "다음" button and preview elements
- **Responsive**: 2-col grid on mobile, 3-col on `sm:` for mood selector
- **No backend dependency**: Wizard logs form data to console with alert placeholder. `handleSubmit` is ready for Supabase insert.

### Remaining Dependencies for Next Subtasks

- **Backend lane**: `events` table in Supabase + `supabase.from('events').insert()` call in `handleSubmit`
- **Auth lane**: 카카오 OAuth must be integrated before event creation can associate `host_id`
- **Asset lane**: PWA icons (`/icons/icon-192.png`, `/icons/icon-512.png`) and default cover SVGs (`/covers/*.svg`) need to be designed/placed
- **OG meta**: `/event/[id]` SSR page with dynamic OG meta depends on backend data
