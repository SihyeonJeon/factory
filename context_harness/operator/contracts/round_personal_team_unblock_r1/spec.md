# round_personal_team_unblock_r1 — Personal Team 빌드 unblock (좁은 정밀 라운드)

**Stage:** coding_1st
**Implementer:** codex
**Verifier:** codex (별도 fresh read-only)
**Plan meeting:** 2026-04-24, claude+codex 합의 acceptance 3개
**v5.8 first case:** 좁은 단일 책임 라운드. 사용자 피드백 (2026-04-24) "deep / 정밀" 패턴.

## Context
사용자 실기기 빌드 시도 중 5건 에러:
1. `applesignin`, `associated-domains` capability — Personal Team "시현 전" 미지원.
2. `com.apple.developer.background-modes` — invalid entitlement key (Apple 표준 아님).
3. UnfadingWidget / UnfadingShareExtension — DEVELOPMENT_TEAM 미상속.

## Acceptance (≤3, Codex 합의)

### 1. Entitlements paid-only 키 제거
- `App/MemoryMap.entitlements` 에서 다음 3 키 **삭제**:
  - `com.apple.developer.applesignin`
  - `com.apple.developer.associated-domains`
  - `com.apple.developer.background-modes`
- `project.yml.targets.MemoryMap.info.properties.UIBackgroundModes = ["fetch", "processing"]` 유지 (이미 있음, 검증).
- 결과: entitlements 파일은 Personal Team 으로 빌드 가능.
- Paid 전환 시 별도 라운드에서 paid entitlements 활성화 (deferred).

### 2. 3 Target DEVELOPMENT_TEAM 상속 일관
- `project.yml`:
  - `targets.MemoryMap.settings.base.DEVELOPMENT_TEAM = "$(DEVELOPMENT_TEAM)"` (이미 base settings 사용 중인지 확인 후 명시)
  - `targets.UnfadingWidget.settings.base.DEVELOPMENT_TEAM = "$(DEVELOPMENT_TEAM)"`
  - `targets.UnfadingShareExtension.settings.base.DEVELOPMENT_TEAM = "$(DEVELOPMENT_TEAM)"`
- 사용자가 명령행에서 `DEVELOPMENT_TEAM=$TEAM_ID` 한 번 주입하면 3 target 동시 적용.

### 3. Apple Sign in / Universal Link 진입점 비활성 (custom scheme 유지)
- `AuthLandingView`: Sign in with Apple 버튼 + 분리선("또는") 모두 미노출.
  - 가드: `PaidDeveloperFeatures.signInWithAppleAvailable` static 상수 (기본 false).
  - 빌드 flag 가 아닌 단순 boolean — paid 전환 시 한 줄 변경.
- `DeepLinkRouter`: `unfading://...` custom scheme 동작 유지. `https://unfading.app/memory/<id>` Universal Link 파싱은 유닛 테스트 그대로 (실 동작은 AASA 부재로 사용 안 됨, evidence/notes.md 명시).

## Out of scope
- Paid Developer Program 전환 시 paid entitlements 재활성화 (별도 라운드).
- AASA 파일 deploy.
- Supabase Apple Provider 활성.
- Apple Sign in 코드 자체 삭제 — 가드만, 코드 보존.

## 빌드 검증
- `xcodegen generate`
- `xcodebuild -project MemoryMap.xcodeproj -scheme MemoryMap -configuration Debug -destination 'generic/platform=iOS' -allowProvisioningUpdates DEVELOPMENT_TEAM=<TEAM_ID> CODE_SIGN_STYLE=Automatic build` (operator 실기기 명령으로 사후 검증)
- 시뮬레이터 회귀 테스트: `xcodebuild test ... -derivedDataPath .deriveddata/r61` 통과.

## 아티팩트
- `contracts/round_personal_team_unblock_r1/file_whitelist.txt`
- `meetings/2026-04-24_round_personal_team_unblock_plan.md` (Codex Challenge Section 본문 포함)
- `reports/round_personal_team_unblock_r1/evidence/notes.md` (deferred paid 전환 라운드 spec, 사용자 빌드 명령 지침)
