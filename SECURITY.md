# Security Policy

> 이 문서는 프로젝트 전체를 관장하는 보안 규칙이다.
> 모든 에이전트는 코드 변경 전 이 파일을 참조해야 한다.

## 1. 인증 (Authentication)

- 모든 보호 API 엔드포인트는 `supabase.auth.getUser()` 호출 필수
- 세션 쿠키 기반 인증 — 서버 컴포넌트에서 `createServerSupabaseClient()` 사용
- OAuth 콜백의 `next` 파라미터: `startsWith("/")`, `!startsWith("//")`, `!includes("@")` 검증
- 카카오톡 인앱 브라우저에서 OAuth 차단 (`KakaoLoginGate`)

## 2. 인가 (Authorization)

- **RLS 필수**: 모든 Supabase 테이블에 Row Level Security 정책 적용
- **SECURITY DEFINER 함수**: 반드시 함수 내부에서 `auth.uid()` 검증
  - API 라우트에서만 인가하면 안 됨 — 클라이언트 SDK로 직접 RPC 호출 가능
- **호스트 전용 작업**: settlement, reminders — `events.host_id = auth.uid()` 확인
- **참가자 전용 작업**: media upload — `guest_states` 참여 확인

## 3. 입력 검증 (Input Validation)

- UUID 파라미터: `/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i`
- Enum 값: 서버에서 화이트리스트 검증 (클라이언트 검증만으로 불충분)
- 문자열 길이: 제목 100자, 설명 500자, 장소 100자
- 파일 업로드: MIME 화이트리스트 (JPEG, PNG, WebP, HEIC), 10MB 제한, UUID 경로
- JSON 파싱: `try { await request.json() } catch { 400 }` 패턴 필수
- 금액: 최대 1억 원 제한

## 4. XSS 방어

- `dangerouslySetInnerHTML` 사용 금지
- `innerHTML` 직접 조작 금지
- React 기본 이스케이핑에 의존 — 사용자 입력을 JSX 텍스트 노드로만 렌더링

## 5. 비밀 관리 (Secrets)

- `.env.local`에만 비밀 저장 — `.gitignore`에 포함 확인
- `SUPABASE_SERVICE_ROLE_KEY`: 서버 사이드에서만 사용, 클라이언트 번들에 포함 불가
- `NEXT_PUBLIC_*` 접두사가 붙은 변수만 클라이언트에 노출
- 에러 메시지에 내부 설정 세부사항 노출 금지 (예: "missing service role key" → "서버 오류")

## 6. HTTP 보안 헤더

`next.config.ts`에서 설정:
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `Referrer-Policy: strict-origin-when-cross-origin`

## 7. Service Worker 보안

캐시에서 제외해야 하는 경로:
- `/api/*` — 인증 토큰 포함 응답
- `/_next/data/*` — 서버 데이터
- `/dashboard/*`, `/create`, `/login`, `/auth/*` — 인증 의존 페이지

## 8. 파일 업로드 보안

- MIME 타입 화이트리스트로 허용된 타입만 수락
- UUID 기반 저장 경로 — 사용자 제공 파일명을 경로에 사용하지 않음
- Supabase Storage RLS로 참가자만 접근 가능
- 이벤트당 최대 10장 제한

## 9. 코드 리뷰 보안 체크리스트

변경 시 아래 항목 확인:
- [ ] 새 API 엔드포인트에 auth 체크 있는가?
- [ ] 새 DB 쿼리에 RLS가 적용되는가?
- [ ] 사용자 입력이 적절히 검증되는가?
- [ ] 비밀이 클라이언트에 노출되지 않는가?
- [ ] 에러 메시지가 내부 구현을 노출하지 않는가?
- [ ] SECURITY DEFINER 함수에 auth.uid() 체크가 있는가?
