# TestFlight Submission Checklist — 2026-04-24

Owner: operator / release owner
App: `MemoryMap` / Unfading
Bundle products to register: `com.jeonsihyeon.memorymap.premium.monthly`, `com.jeonsihyeon.memorymap.premium.yearly`

## Submission Gate Checklist

- [ ] Apple Developer team ID 등록
- [ ] App Store Connect 앱 레코드 등록
- [ ] App Store Connect subscription product 등록
- [ ] `com.jeonsihyeon.memorymap.premium.monthly` 생성 및 검토 준비
- [ ] `com.jeonsihyeon.memorymap.premium.yearly` 생성 및 검토 준비
- [ ] Entitlement capability 확인: Sign in with Apple
- [ ] Entitlement capability 확인: Background fetch
- [ ] Entitlement capability 확인: Associated Domains
- [ ] Entitlement capability 확인: Push Notifications
- [ ] `https://unfading.app/.well-known/apple-app-site-association` 배포 및 응답 검증
- [ ] Supabase Dashboard: HIBP leaked-password protection 활성화
- [ ] Supabase Dashboard: Email Confirm 정책 최종 점검
- [ ] Supabase Dashboard: Apple Provider Services ID 연결 점검
- [ ] Privacy manifest 최종 검토
- [ ] App Privacy Data Collection 명세서 입력
- [ ] TestFlight internal/external tester 초대
- [ ] App Store 제출 메타데이터 작성
- [ ] 스크린샷 업로드
- [ ] 설명/키워드/지원 URL 입력
- [ ] 카테고리 선택
- [ ] 연령 등급 설문 완료
- [ ] 실제 서명 archive/export/upload 실행

## Operator Notes

- `workspace/ios/scripts/archive.sh` is the archive/export entrypoint once `TEAM_ID` is available.
- `workspace/ios/scripts/export-options.plist` is configured for `app-store-connect`, automatic signing, symbol upload, and build/version management.
- Universal Links should not be considered validated until the AASA file is live and device-tested.
- TestFlight upload readiness is blocked externally even though the in-repo helper files lint successfully.
