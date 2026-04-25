# Eval Protocol — round_sheet_velocity_projection_r1

## Author / Verifier
- Author: implementer Codex (fresh session).
- Verifier: 별도 fresh session. Author ≠ Verifier.

## 3-axis verification

### Code
- `UnfadingBottomSheet.swift:70-102` (drag resolution) 의 nearest-only 로직 → velocity-aware 로 변경 확인.
- 기존 `velocityProjectionSeconds = 0.2` 는 유지 또는 명시 threshold (예: |v| > 800pt/s) 와 함께 동작.

### Runtime
- `xcodebuild test` 신규 4 case PASS.
- (선택) simulator drag UITest 시뮬은 시뮬레이터 한계로 skip 허용. 실기기 smoke 는 사용자.

### Process
- spec ↔ acceptance ↔ implementation ↔ tests 일관.
- evidence/notes.md 가 §D 형식 + drag 표.
