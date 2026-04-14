# Round 40 — 2026-04-14 (Production Readiness Audit)

## 입력
- Round 39 기능 확장 완료 후 프로덕션 배포 전 최종 감사
- 오퍼레이터 → 4개 에이전트 병렬 위임 구조

## 에이전트 구조
```
오퍼레이터 (교차 대조 + 설계 판단)
  ├─ Codex (1차 감사): 보안/데이터/성능/설정
  ├─ Explore (1차 감사): 누락 기능/엣지케이스/SEO
  ├─ Agent A (수정): 보안·데이터 무결성 5건
  ├─ Agent B (수정): UX boundaries + SEO + 커버 분석
  └─ 오퍼레이터 (수정): 커버 업로드 경로 설계 결정
```

## 감사 결과 (Codex + Explore 교차 대조)

### Codex 발견
| ID | Severity | Summary | 판정 |
|----|----------|---------|------|
| R40-001 | Critical | 인증 유저가 아무 이벤트에 RSVP 가능 → 개인정보 접근 | **설계 의도** (링크 공유 모델) |
| R40-002 | High | 정산 upsert → 납부 상태 초기화 | **수정** |
| R40-003 | High | 사진 제한 race condition | **수정** |
| R40-004 | High | env 검증 없음 (런타임 크래시) | **후순위** (Vercel 환경 변수 관리) |
| R40-005 | Medium | 리마인더 에러 핸들링 미흡 | **수정** |
| R40-006 | Medium | getMyEvents unbounded | **수정** (.limit(50)) |
| R40-007 | High | 커버 업로드 경로 ≠ Storage RLS | **수정** (서버 사이드 업로드) |
| R40-008 | Medium | 이벤트 생성 title trim 누락 | **수정** |

### Explore 발견
| 항목 | 조치 |
|------|------|
| Error boundaries 5개 라우트 누락 | **수정** (6개 생성) |
| Loading states 6개 라우트 누락 | **수정** (5개 생성) |
| robots.txt / sitemap 없음 | **수정** |
| Rate limiting 없음 | **후순위** (Vercel Edge) |
| CSP 헤더 없음 | **후순위** |
| console.log 정리 | **후순위** |

### R40-001 설계 판단 기록
모먼트는 "링크 기반 접근" 모델 (Google Docs "링크가 있는 모든 사용자"와 동일):
- UUID v4 = 2^122 엔트로피 → 추측 불가
- 카카오톡 공유 = 초대장
- 참석자 간 데이터 공유는 제품 기능 (버그 아님)
- 필요 시 향후 초대 코드/승인 시스템으로 확장 가능

## 프로세스 점수
- 보안: 9/10 (링크 모델 수용, Storage RLS 수정)
- 기능: 10/10
- 접근성: 9/10
- 성능: 9/10 (pagination 추가)
- 코드 품질: 9/10

## 교훈
- S-015: Storage RLS 경로 기반 정책 + 업로드 경로 일치 검증 필수
- S-016: upsert는 상태 보존이 필요한 데이터에 사용 금지

## 후순위 (Round 41+)
- env 검증 모듈 (zod schema)
- Rate limiting (Vercel Edge / upstash)
- CSP 헤더
- console.log → structured logging (Sentry 등)
