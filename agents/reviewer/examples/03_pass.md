## Example: PASS verdict

This review demonstrates correct PASS scoring — no critical or high issues. Only low-priority improvements that don't affect functionality, security, or usability.

### Key calibration points:
- All acceptance criteria met
- No security vulnerabilities found
- Functional flows work end-to-end
- Only cosmetic/optimization suggestions remain
- PASS does NOT mean "perfect" — it means "ready to ship"

```json
{
  "verdict": "PASS",
  "findings": [
    {
      "id": "L-1",
      "severity": "low",
      "file": "src/components/create/create-event-wizard.tsx",
      "line": 78,
      "summary": "Success feedback uses alert() — consider toast for better UX",
      "fix": "Replace with toast component",
      "acceptance_ref": "",
      "category": "ux"
    },
    {
      "id": "L-2",
      "severity": "low",
      "file": "src/app/layout.tsx",
      "line": 15,
      "summary": "No prefers-reduced-motion media query for animations",
      "fix": "Add reduced-motion media query to globals.css",
      "acceptance_ref": "",
      "category": "accessibility"
    }
  ],
  "lanes_impacted": [],
  "summary": "All acceptance criteria met. Auth flows, RLS policies, RSVP, dashboard, photos, and PWA all functional. Only 2 low-priority UX/accessibility suggestions. Ready for release."
}
```
