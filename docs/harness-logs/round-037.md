# Round 37 — 2026-04-14 (후순위 해소 + Codex 교차 검증)

## 입력
- Round 36 후순위 5건 (FCM SW 충돌, config 주입, N+1 profile, PhotoSwipe lazy, offline fallback)

## 검증자
- **Claude Code**: 구현 (1차)
- **Codex**: 교차 검증 (6건 발견: H-1, M-4, L-1)
- **Claude Code**: Codex 피드백 반영 수정 (2차)

## 결과

### 구현 항목
| 항목 | 파일 | 설명 |
|------|------|------|
| FCM SW 스코프 분리 | `fcm.ts`, `firebase-messaging-sw.js` | root scope 충돌 해소 → `/firebase-cloud-messaging-push-scope` |
| FCM config 주입 | `fcm.ts`, `firebase-messaging-sw.js` | postMessage + Cache Storage 영속화 |
| PhotoSwipe lazy import | `photos-page-view.tsx` | `next/dynamic` + `ssr: false` |
| Offline fallback | `sw.js`, `offline.html` | 오프라인 네비게이션 시 폴백 페이지 |
| Profile 캐시 | `use-realtime-guests.ts` | `useRef(Map)` 캐시 + eventId 변경 시 클리어 |

### Codex 교차 검증 결과
| ID | Severity | Summary | 조치 |
|----|----------|---------|------|
| R37-001 | H | sw.js 오프라인 폴백: catch가 fetchPromise 내부에서 소멸 → 폴백 미도달 | **수정**: catch 내부에서 직접 offline.html 반환 |
| R37-002 | M | sw.js: 5xx/redirect 응답도 캐시 저장 | **수정**: `response.ok && response.type === "basic"` 가드 |
| R37-003 | M | FCM SW 업데이트 시 config 유실 | **수정**: Cache Storage에 config 영속화 + activate에서 복원 |
| R37-004 | M | notificationclick이 임의 URL open → open redirect | **수정**: same-origin 검증 + pathname 비교 |
| R37-005 | M | 초기 fetch와 realtime INSERT 간 레이스 → 게스트 유실 | **수정**: Map 기반 merge로 양쪽 데이터 통합 |
| R37-006 | L | profileCache unbounded growth | **수정**: eventId 변경 시 cache clear |

## 프로세스 점수
- 보안: 9/10 (open redirect 차단 완료)
- 기능: 9/10
- 접근성: 9/10
- 성능: 8/10 (FCM 해결, N+1 캐시, lazy import)
- 코드 품질: 9/10

## 교훈
- S-010: SW fetch handler에서 `.catch()` 체이닝 시, 내부 `.catch()`가 에러를 소멸시키면 외부 `.catch()`는 도달 불가 — 에러 전파 경로를 추적할 것
- S-011: SW에 캐시 저장 시 반드시 `response.ok` 체크 — 5xx/redirect 캐시는 사용자에게 복구 불가능한 상태 유발
- S-012: push notification data는 공격자 제어 입력 — `openWindow()`에 전달 전 same-origin 검증 필수

## 후순위 (Round 38)
- 현재 미해결 항목 없음 — 전체 후순위 해소 완료
- 다음 라운드: 전체 기능 통합 점검 + production readiness audit
