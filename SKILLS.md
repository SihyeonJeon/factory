# Skills — Proven Patterns & Best Practices

Shared knowledge base for all agents. When a technique produces measurably better results, record it here. All agents MUST check this file before starting work.

---

## iOS Development

### S-1: xcodegen before xcodebuild (always)
New `.swift` files won't compile without regenerating the project.
```
xcodegen generate && xcodebuild -project *.xcodeproj -scheme <scheme> ...
```

### S-2: Stale derived data causes old binary to launch
Delete derived data before evaluation screenshots to avoid reviewing stale UI.
```
rm -rf .deriveddata/evaluation
```

### S-3: PHAsset photo loading pattern
Use `PHImageManager.default().requestImage()` with `isNetworkAccessAllowed: true` inside `withCheckedContinuation`. Cache by local identifier.

### S-4: 44pt minimum touch targets
Every interactive element needs `.frame(minHeight: 44)` + `.contentShape(Rectangle())`. This is the most common HIG BLOCKER.

### S-5: Location permission — on launch (HF3 revised)
**Updated 2026-04-14:** HF3 피드백으로 앱 시작 시 위치 권한 요청 허용. `UnfadingApp.swift`의 `.task`에서 `locationPermissionStore.requestPermission()` 호출.
주의사항:
1. `mapView.showsUserLocation = true` — MKMapView가 자동 요청하므로 `.authorized` 체크 후 설정
2. 권한 거부 시 graceful fallback — 지도 기능은 정상 동작, 현재 위치만 비활성화

### S-6: Dynamic Type compliance
Never use `.font(.system(size: N))`. Use semantic styles (`.footnote`, `.subheadline`) with `.design(.rounded)`. Use `@ScaledMetric` for icon sizes.

---

## Harness Operations

### S-7: extract_blockers() false positives
The regex matches "BLOCKER" in advisory text like "Why BLOCKER, not ADVISORY". Always read the report text — never trust `evaluation_passed` boolean alone.

### S-8: Codex dispatch — absolute paths required
```python
cwd = Path('/Users/.../factory/.worktrees/_integration').resolve()
```
Relative paths break codex CLI.

### S-9: Opus rate limiting — graceful fallback
Opus (red_team_reviewer) returns empty responses under Pro plan rate limits. Orchestrator has retry + fallback to alternative roles. Log the gap.

### S-10: Brief file whitelist enforcement
Codex respects "edit only listed files" — but verify by checking which files actually changed post-dispatch. If an unlisted file is needed, update the brief and re-dispatch.

---

## Evaluation

### S-11: Three-evaluator cross-check
- red_team_reviewer (opus): code correctness, security, regressions
- hig_guardian (sonnet): HIG, Dynamic Type, VoiceOver, touch targets
- visual_qa (sonnet): screenshot layout, visual regression

If 2+ flag the same file → mandatory fix. If 1 flags → fix but note disagreement.

### S-12: Runtime screenshot for visual QA
Build → install on simulator → launch → `xcrun simctl io booted screenshot`. Evaluation must use fresh screenshot, not cached.

### S-13: Claude Code CLI permission modes
Valid `--permission-mode` values: `acceptEdits`, `auto`, `bypassPermissions`, `default`, `dontAsk`, `plan`.
- 자율 구현 (비대화형, 하네스 디스패치): use `bypassPermissions` — 모든 권한 우회, Write/Edit/Bash 가능
- 대화형 구현: use `auto` — 편집은 자동, 위험 작업은 확인 요청
- 편집만 (Bash 불가): use `acceptEdits`
- Read-only evaluation: use `plan`
- `auto-edit` is NOT valid — causes immediate failure.
- `auto`/`acceptEdits`는 비대화형(subprocess) 실행 시 쓰기 권한 승인 불가 → `bypassPermissions` 필수.

### S-14: Codex review vs gitignored workspace
`codex exec review --uncommitted`는 git-tracked 파일만 검사. `workspace/`가 `.gitignore`에 포함되면 변경사항을 감지하지 못함.
**해결:** gitignored 디렉토리의 코드 리뷰는 `sprint_eval` 타입으로 파일 기반 프롬프트 사용. `review_code()`는 git-tracked 파일에만 사용.

### S-16: XCUITest screenshot extraction from xcresult
xcresult 번들에서 스크린샷 추출 방법:
1. `xcrun xcresulttool get test-results tests --path <bundle>` → 테스트 목록 (JSON)
2. `xcrun xcresulttool get test-results activities --test-id <id> --path <bundle>` → 첨부 파일 목록 (`payloadId` 포함)
3. `xcrun xcresulttool export object --legacy --path <bundle> --output-path <dest> --id <payloadId> --type file` → PNG 추출
sqlite 방식(구 포맷)과 활동 기반 방식(신 포맷) 모두 `payloadId`로 export 가능.

### S-15: Codex CLI `-C` flag position
`codex exec review` 사용 시 `-C <dir>` 플래그를 `review` 앞에 배치해야 함.
- 올바른 순서: `codex exec -C /path -m model --full-auto review`
- 잘못된 순서: `codex exec review -m model -C /path` → "unexpected argument '-C'" 에러
- 일반 `codex exec <prompt>` 에서는 `-C`가 prompt 뒤에 와도 됨.

### S-18: Codex CLI session resume for multi-round peer meetings (v5)
Operator↔operator peer 회의는 **같은 codex 세션을 여러 턴에 걸쳐 이어가야** 문맥이 유지된다. 패턴:
1. 첫 호출: `codex exec --sandbox read-only --skip-git-repo-check "<prompt>"` — 출력에서 `session id: <uuid>` 캡처.
2. 후속 턴: `codex exec --sandbox read-only --skip-git-repo-check resume <uuid> "<prompt>"`.
3. **플래그 순서 주의:** `--sandbox`, `--skip-git-repo-check` 등 옵션은 `resume` 서브커맨드 **앞**에 와야 함. 뒤에 놓으면 `error: unexpected argument '--sandbox'`.
4. 각 회의마다 새 세션. 다른 회의를 같은 세션에 섞지 말 것 (cross-meeting 오염).
5. 401 / idle timeout 발생 시: blackboard에 기록 → `/codex:setup` 재실행 → 필요하면 escalation ladder(REGULATION §6) 타기. 조용한 재시도 금지.

**왜:** 2026-04-19 v5 kickoff meeting에서 rescue 스킬이 401/hang으로 막혔고, codex CLI 직접 호출 + resume으로 3-round peer review를 성공적으로 수렴했다. `codex:rescue`는 fork 실행 모델이라 세션 공유가 어려움 — 공동 운영자 모델에서는 **resume 기반 단일 세션**이 표준.

---

## S-17: 바이브 코딩 안티패턴 방지 규율

> **v5.6+ note (2026-04-23):** This checklist is FORWARD-LOOKING. At
> `round_foundation_reset_r1` kickoff the workspace was a ~12-file MVP with no
> `UnfadingTheme` and no Korean UI. Pre-round-2 code did not comply with most
> items below. Compliance begins with round 2 deliverables. Earlier references
> in this file that assume compliance (e.g., "현재 161건 적용") describe a
> hypothetical advanced workspace, not this repo. See
> `docs/exec-plans/sprint-history-pre-v5.md` for context.

시니어 iOS 개발자가 자연스럽게 수행하지만, AI/바이브 코딩이 반복적으로 놓치는 항목.
코드 작성 및 리뷰 시 아래 체크리스트를 반드시 확인한다.

### 메모리 & 동시성

- [ ] **클로저 내 `[weak self]` 사용** — 네트워크 콜백, Timer, NotificationCenter 옵저버 등 escaping 클로저에서 retain cycle 방지. 현재 프로젝트에서 `[weak self]` 사용은 2개 파일(CameraCaptureView, RewindReminderStore)에 한정됨.
- [ ] **Task 취소 처리** — `Task {}`로 시작한 비동기 작업은 `.onDisappear` 또는 `deinit`에서 `.cancel()` 호출. 뷰 이탈 시 불필요한 네트워크/디스크 작업이 계속 실행됨.
- [ ] **@MainActor 일관성** — Store/ViewModel은 클래스 레벨에 `@MainActor` 선언. 개별 메서드에만 붙이면 data race 위험. 현재 프로젝트는 적절히 적용됨 (16개 파일).

### 에러 처리

- [ ] **`try?` 무조건 무시 금지** — `try?`로 에러를 삼키면 사용자에게 실패 원인을 알려줄 수 없음. 현재 5곳에서 `try?`로 Supabase 업로드/가입 실패를 무시 중 (`MemoryComposerSheet.swift:626`, `GroupHubView.swift:345` 등). 최소한 로그 기록 또는 사용자 알림 필요.
- [ ] **`try!` 사용 금지** — 런타임 크래시 유발. 항상 `do-catch` 또는 `try?` + 에러 핸들링 사용.

### 인라인 컬러 & 테마

- [ ] **`.white`, `.black` 직접 사용 금지** — `UnfadingTheme.textOnPrimary`, `UnfadingTheme.textOnOverlay` 등 테마 토큰 사용. 다크 모드 대응 불가. 현재 `DiaryCoverCustomizationView`, `MemoryPinMarker`, `YearEndReportView` 등 6개 이상 파일에서 `.white` 직접 사용 중.
- [ ] **`.black.opacity(N)` 오버레이** — `UnfadingTheme`에 오버레이 전용 색상 토큰 추가 후 사용. `UnfadingHomeView.swift:828`에서 `Color.black.opacity(0.45)` 하드코딩 발견.

### 앱 라이프사이클 & 엣지 케이스

- [ ] **백그라운드 전환 시 상태 저장** — `scenePhase` 변경 시 미저장 데이터 persist. 현재 `UnfadingHomeView`만 `scenePhase` 감시 중 — 다른 편집 화면(MemoryComposer 등)은 미대응.
- [ ] **네트워크 끊김 처리** — 오프라인 시 Supabase 호출 실패에 대한 재시도/큐잉 로직 필요. `try?`로 무시하면 데이터 유실.
- [ ] **권한 거부 후 재요청 UX** — 카메라/위치/사진 권한 거부 후 설정 앱으로 안내하는 UI 필요. `CameraCaptureView`만 구현됨.

### 보안

- [ ] **민감 데이터는 Keychain에 저장** — `UserDefaults`에 토큰/비밀번호 저장 금지. 현재 `AuthManager`가 `UserDefaults.standard` 사용 — 인증 토큰 저장 시 Keychain 사용 필수 검토.
- [ ] **API 키 하드코딩 금지** — `.xcconfig` 또는 환경변수에서 주입. 소스 코드에 평문 노출 방지.

### 성능

- [ ] **이미지 lazy loading** — 리스트/그리드에서 화면에 보이는 항목만 로딩. `LazyVStack`/`LazyVGrid` 사용 확인.
- [ ] **불필요한 리렌더링 방지** — `@State`/`@Binding` 스코프 최소화. 큰 뷰를 작은 하위 뷰로 분리하여 body 재계산 범위 축소.
- [ ] **`print()` 디버그 로그 제거** — 프로덕션 빌드에 `print()` 남기지 않음. 현재 프로젝트는 0건 (양호).

### 접근성

- [ ] **모든 인터랙티브 요소에 `accessibilityLabel`** — 아이콘 버튼, 이미지 버튼 등 텍스트 없는 요소에 필수. 현재 161건 적용 (양호하나, 신규 뷰 추가 시 누락 주의).
- [ ] **`accessibilityHint`로 동작 설명** — "탭하면 메모리를 삭제합니다" 등 파괴적 동작에 힌트 추가.
- [ ] **VoiceOver 순서 검증** — `.accessibilitySortPriority()`로 논리적 읽기 순서 보장.

### 국제화

- [ ] **하드코딩된 한국어 문자열 → `String(localized:)`** — 향후 다국어 지원 대비. 현재는 한국어 전용이지만 `Localizable.xcstrings` 기반으로 전환 준비.
- [ ] **날짜/숫자 포맷은 `DateFormatter`/`NumberFormatter` 사용** — 로케일별 차이 대응.

### 테스트

- [ ] **Store/ViewModel에 의존성 주입** — 테스트 시 mock 교체 가능하도록 프로토콜 기반 DI. `init(userDefaults:)` 패턴 (AuthManager) 좋은 예시.
- [ ] **에지 케이스 테스트** — 빈 배열, nil 값, 네트워크 타임아웃 등 행복 경로 외 시나리오 검증.
- [ ] **UI 테스트로 접근성 검증** — `XCUIElement.isAccessibilityElement` 확인.
