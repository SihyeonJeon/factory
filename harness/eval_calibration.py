"""Evaluation calibration layer for the harness.

Provides:
1. Few-shot examples for evaluator scoring calibration
2. Structured output format (JSON) from evaluators
3. Cross-evaluator agreement check
4. Evaluator consistency scoring

This addresses the core weakness: evaluators using "general LLM judgment"
instead of calibrated criteria. Few-shot examples anchor the evaluator's
BLOCKER/ADVISORY/PASS classification to concrete precedents.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path


# --------------------------------------------------------------------------- #
# Few-shot calibration examples                                                #
# --------------------------------------------------------------------------- #

CODE_REVIEW_FEW_SHOT = """
## Scoring calibration — follow these precedents exactly

### Example 1: BLOCKER
**Finding:** `RewindReminderStore.swift` init body triggers `didSet` → calls `requestAuthorization()` on cold launch, firing a notification permission dialog before the user takes any action.
**Why BLOCKER:** Violates iOS UX norms (permission requests require user context), causes App Store rejection risk, and the fix is a structural change (move defaults to inline properties).
**Verdict:** BLOCKER — behavioral defect with user-facing impact and App Store risk.

### Example 2: BLOCKER
**Finding:** `NSCameraUsageDescription` key missing from Info.plist. Camera feature exists in code but will crash on device.
**Why BLOCKER:** Runtime crash on real hardware. App Store will reject.
**Verdict:** BLOCKER — missing required platform configuration.

### Example 3: ADVISORY (not a blocker)
**Finding:** Mixed EN/KR accessibility strings — some labels are English, some Korean.
**Why ADVISORY:** Functional but inconsistent. Does not crash, does not block submission, does not degrade UX for any user group.
**Verdict:** ADVISORY — cosmetic inconsistency, defer to next polish round.

### Example 4: ADVISORY (not a blocker)
**Finding:** `@unknown default: break` in camera permission switch. Could silently ignore future permission states added by Apple.
**Why ADVISORY:** Correct defensive pattern per Swift best practices. No current behavioral impact.
**Verdict:** ADVISORY — future-proofing concern, not a present defect.

### Example 5: PASS (not even advisory)
**Finding:** Test count is 56 instead of the expected 58.
**Why PASS:** Test count differences can result from test replacement (2 new tests replacing 1 old test). If all tests pass, the count discrepancy is not a quality signal.
**Verdict:** PASS — informational only.

## Classification rules
- BLOCKER = will cause crash, App Store rejection, data loss, or accessibility failure that prevents a user group from completing a core flow
- ADVISORY = real issue that should be fixed but does not prevent release or harm users
- PASS = informational observation, no action needed
- When uncertain between BLOCKER and ADVISORY, check: "Would Apple reject the app for this?" If no → ADVISORY.
"""

HIG_AUDIT_FEW_SHOT = """
## Scoring calibration — follow these precedents exactly

### Example 1: BLOCKER
**Finding:** Two TextFields side-by-side in an HStack inside a Form row. At Dynamic Type ≥ .xLarge, text clips and overlaps. VoiceOver treats both fields as one cell.
**Why BLOCKER:** Accessibility failure — a user group cannot complete the form. HIG violation: interactive elements must be individually focusable.
**Verdict:** BLOCKER — accessibility barrier in a primary flow.

### Example 2: BLOCKER
**Finding:** `.font(.system(size: 42, ...))` hardcoded font size. Dynamic Type users see no scaling.
**Why BLOCKER:** HIG requires all text to respond to Dynamic Type. Hardcoded sizes are explicit violations.
**Verdict:** BLOCKER — use `.largeTitle.monospaced()` or `@ScaledMetric`.

### Example 3: ADVISORY (not a blocker)
**Finding:** `.lineLimit(1)` on note preview truncates long notes without visual indicator.
**Why ADVISORY:** Truncation is a design choice. The full note is available on tap. No user is blocked.
**Verdict:** ADVISORY — minor UX improvement opportunity.

### Example 4: ADVISORY (not a blocker)
**Finding:** Decorative RoundedRectangle color bar is exposed to VoiceOver.
**Why ADVISORY:** VoiceOver reads it as an empty element. Annoying but not blocking — user can skip past it.
**Verdict:** ADVISORY — add `.accessibilityHidden(true)` in next polish pass.

### Example 5: PASS (not even advisory)
**Finding:** App uses Korean strings for some labels and English for others.
**Why PASS:** The app targets Korean users. Mixed language in labels is a localization choice, not a HIG violation.
**Verdict:** PASS — localization decision.

## Classification rules
- BLOCKER = HIG violation that prevents a user group from completing a flow, or that Apple would reject
- ADVISORY = HIG recommendation that improves UX but does not block any user
- PASS = observation that does not represent a HIG issue
- 44pt minimum touch target: BLOCKER if interactive element is below 44pt
- Dynamic Type: BLOCKER if text uses hardcoded font sizes
- VoiceOver: BLOCKER if an interactive element has no label or is unreachable
"""

VISUAL_QA_FEW_SHOT = """
## Scoring calibration — follow these precedents exactly

### Example 1: BLOCKER
**Finding:** Cost entry LabeledContent is nested inside the Note VStack. VoiceOver narrates it as part of the note text.
**Why BLOCKER:** Semantic misplacement causes accessibility confusion. Users cannot distinguish cost from note content.
**Verdict:** BLOCKER — structural layout error affecting accessibility.

### Example 2: BLOCKER
**Finding:** Remove member button has ~17pt tap area and fires destructive action with no confirmation.
**Why BLOCKER:** Below HIG 44pt minimum AND destructive without confirmation. Two violations in one element.
**Verdict:** BLOCKER — destructive action + undersized target.

### Example 3: ADVISORY (not a blocker)
**Finding:** Theme selection buttons missing `.accessibilityHint`.
**Why ADVISORY:** Buttons are functional and labeled. Hint is supplementary — its absence does not prevent usage.
**Verdict:** ADVISORY — enhancement to VoiceOver experience.

### Example 4: ADVISORY (not a blocker)
**Finding:** 4 surfaces not verified visually (bottom sheet, reactions, camera, cluster tap) because screenshot only shows home screen.
**Why ADVISORY:** Screenshot coverage gap, not a code defect. Request additional screenshots but do not block merge.
**Verdict:** ADVISORY — QA coverage gap, not a product defect.

## Classification rules
- BLOCKER = visible defect in screenshot OR code-verified structural error affecting a user group
- ADVISORY = improvement opportunity or screenshot coverage gap
- PASS = confirmed-passing surface
- If a surface is NOT in the screenshot: verify via code inspection. If code inspection reveals a BLOCKER-level issue, classify it as BLOCKER with "(code-verified)" tag.
- If the screenshot shows a native, clean layout with no overlaps: the home screen PASSES.
"""


# --------------------------------------------------------------------------- #
# Structured evaluation output                                                 #
# --------------------------------------------------------------------------- #

EVALUATOR_OUTPUT_SCHEMA = {
    "type": "object",
    "properties": {
        "verdict": {
            "type": "string",
            "enum": ["PASS", "CONDITIONAL_PASS", "BLOCKED"],
        },
        "blockers": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "id": {"type": "string"},
                    "file": {"type": "string"},
                    "line": {"type": "integer"},
                    "description": {"type": "string"},
                    "fix": {"type": "string"},
                },
                "required": ["id", "file", "description"],
            },
        },
        "advisories": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "id": {"type": "string"},
                    "file": {"type": "string"},
                    "description": {"type": "string"},
                },
                "required": ["id", "description"],
            },
        },
        "passes": {
            "type": "array",
            "items": {"type": "string"},
        },
        "summary": {"type": "string"},
    },
    "required": ["verdict", "blockers", "advisories", "summary"],
}


def get_calibration_prompt(role: str) -> str:
    """Return the few-shot calibration section for an evaluator role."""
    prompts = {
        "red_team_reviewer": CODE_REVIEW_FEW_SHOT,
        "hig_guardian": HIG_AUDIT_FEW_SHOT,
        "visual_qa": VISUAL_QA_FEW_SHOT,
    }
    return prompts.get(role, "")


# --------------------------------------------------------------------------- #
# Cross-evaluator agreement                                                    #
# --------------------------------------------------------------------------- #

@dataclass
class AgreementResult:
    """Result of cross-evaluator agreement check."""
    unanimous_blockers: list[str]   # flagged by 2+ evaluators
    disputed_blockers: list[str]    # flagged by only 1 evaluator
    agreement_score: float          # 0.0 to 1.0
    should_block: bool


def check_cross_evaluator_agreement(
    reports: dict[str, str],
) -> AgreementResult:
    """Check if multiple evaluators agree on blockers.

    If 2+ evaluators flag the same file/issue, it's a unanimous blocker.
    If only 1 evaluator flags it, it's disputed (still blocks but noted).

    This addresses the self-following problem: a single evaluator's judgment
    is less reliable than agreement across independent evaluators.
    """
    import re

    # Extract blocker mentions per evaluator
    evaluator_blockers: dict[str, set[str]] = {}
    for role, text in reports.items():
        if not text:
            continue
        blockers: set[str] = set()
        # Find file references in blocker sections
        for match in re.finditer(
            r'(?:BLOCKER|blocker|Block)\s*\d*\s*[-—:]\s*.*?`([^`]+\.swift[^`]*)`',
            text,
        ):
            # Normalize to just filename
            path = match.group(1).split("/")[-1].split(":")[0]
            blockers.add(path)
        evaluator_blockers[role] = blockers

    if not evaluator_blockers:
        return AgreementResult([], [], 1.0, False)

    # Find files mentioned by multiple evaluators
    all_files = set()
    for blockers in evaluator_blockers.values():
        all_files.update(blockers)

    unanimous = []
    disputed = []
    for f in all_files:
        count = sum(1 for blockers in evaluator_blockers.values() if f in blockers)
        if count >= 2:
            unanimous.append(f)
        else:
            disputed.append(f)

    # Agreement score: proportion of blockers that are unanimous
    total = len(unanimous) + len(disputed)
    score = len(unanimous) / total if total > 0 else 1.0
    should_block = len(unanimous) > 0 or len(disputed) > 0

    return AgreementResult(
        unanimous_blockers=sorted(unanimous),
        disputed_blockers=sorted(disputed),
        agreement_score=round(score, 2),
        should_block=should_block,
    )
