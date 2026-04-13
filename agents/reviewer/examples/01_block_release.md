## Example: BLOCK_RELEASE verdict

This review demonstrates correct BLOCK_RELEASE scoring — critical security and functionality issues that make the product non-functional or insecure.

### Key calibration points:
- Open redirect = CRITICAL (security)
- Core pages using mock data = CRITICAL (functionality — product is non-functional)
- Missing UUID validation with path traversal = CRITICAL (security)
- SW caching auth responses = HIGH (security)
- Missing PNG icons for PWA install = HIGH (pwa — blocks install prompt)

```json
{
  "verdict": "BLOCK_RELEASE",
  "findings": [
    {
      "id": "C-1",
      "severity": "critical",
      "file": "src/app/auth/callback/route.ts",
      "line": 18,
      "summary": "Open redirect — next param concatenated without validation",
      "fix": "Validate next starts with / and not //",
      "acceptance_ref": "release-blocker-security",
      "category": "security"
    },
    {
      "id": "C-2",
      "severity": "critical",
      "file": "src/app/event/[id]/page.tsx",
      "line": 12,
      "summary": "Event page uses getMockEvent() — all events show same hardcoded data",
      "fix": "Replace with getEventDetail() querying Supabase, call notFound() for missing",
      "acceptance_ref": "epic-1",
      "category": "functionality"
    },
    {
      "id": "H-1",
      "severity": "high",
      "file": "public/manifest.json",
      "line": 12,
      "summary": "PWA manifest has SVG-only icons — Chrome requires PNG for install prompt",
      "fix": "Generate 192x192 and 512x512 PNG icons",
      "acceptance_ref": "epic-2",
      "category": "pwa"
    }
  ],
  "lanes_impacted": ["frontend", "backend"],
  "summary": "2 critical issues (open redirect, mock data on core pages) and 1 high issue (PWA icons) block release. Product is non-functional — all event URLs render the same fake data."
}
```
