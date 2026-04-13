## Example: CONDITIONAL_PASS verdict

This review demonstrates correct CONDITIONAL_PASS scoring — no critical issues remain, but high/medium issues should be fixed before production.

### Key calibration points:
- UUID validation missing but no path traversal possible = HIGH (not critical)
- Error messages leaking internal details = HIGH (security, but not exploitable)
- Missing aria-hidden on decorative SVGs = MEDIUM (accessibility)
- alert() instead of toast = MEDIUM (ux)
- These are real issues but the product IS functional

```json
{
  "verdict": "CONDITIONAL_PASS",
  "findings": [
    {
      "id": "H-1",
      "severity": "high",
      "file": "src/app/api/media/upload/route.ts",
      "line": 35,
      "summary": "eventId not validated as UUID — potential storage path traversal",
      "fix": "Add UUID regex validation at route handler entry",
      "acceptance_ref": "release-blocker-security",
      "category": "security"
    },
    {
      "id": "M-1",
      "severity": "medium",
      "file": "src/components/rsvp/event-rsvp-flow.tsx",
      "line": 42,
      "summary": "RSVP form submits without checking feeIntention when hasFee is true",
      "fix": "Add validation check before submit",
      "acceptance_ref": "epic-2",
      "category": "functionality"
    },
    {
      "id": "M-2",
      "severity": "medium",
      "file": "src/components/photos/photo-swipe-viewer.tsx",
      "line": 245,
      "summary": "Dot indicators are 6px — below 44px WCAG minimum touch target",
      "fix": "Change to span or increase touch target",
      "acceptance_ref": "release-blocker-accessibility",
      "category": "accessibility"
    }
  ],
  "lanes_impacted": ["frontend", "backend"],
  "summary": "Core flows are functional. 1 high security issue (UUID validation) and 2 medium UX/accessibility issues remain. Product is usable but should fix these before wide rollout."
}
```
