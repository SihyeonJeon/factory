# 🖥️ Hardware Scaling & Agent Box Strategy - Unfading (2026-04)

본 문서는 자율형 퍼블리싱 팩토리가 'Unfading (프라이빗 공간 다이어리)' 앱을 안정적으로 빌드하고 App Store에 완전히 자율 무인 배포(Zero-Touch Deployment)하기 위한 **물리적 환경 스케일업 및 운영 전략**을 체계화합니다.

## 🎯 1. 전략의 핵심 (Why Hardware Matters)
자율 에이전트(Claude Code / Aider)를 프롬프트 엔지니어링 단계(단순 텍스트 입출력)를 넘어, **CLI 툴(Expo, Fastlane) 명령어까지 직접 수행하는 'Company Team' 체계**로 격상시키기 위한 SOTA 전략입니다.

1. **iOS 빌드 필수 조건 (The Apple Bottleneck):**
   - Unfading 앱은 지도 기반의 `react-native-maps` 인터랙션, 카메라/사진첩 권한 등 Native Module 컴파일이 필수적이므로 완벽한 macOS 환경(Xcode)이 선제되어야 합니다.
   - 클라우드 호스팅 Mac 대여 비용 대비, 물리적인 **엔트리급 Mac Mini(Apple Silicon)** 기반의 인하우스 구축이 자본 효율성(Make Money) 측면에서 압도적 우위입니다.
2. **YOLO 모드의 물리적 샌드박스화 (True Automation):**
   - 사용자 개입을 차단하는 `--dangerously-skip-permissions` 옵션을 활성화한 AI는, 패키지 삭제, 커밋 푸시, 파일 생성 등 무한한 자유도를 가집니다.
   - 메인 작업용 PC가 '파괴적 할루시네이션(rm -rf 등)' 및 과도한 리소스 100% 점유로부터 오염되는 것을 막기 위한 가장 원시적이지만 확실한 **물리적 망 분리(Physical Sandbox)** 수단입니다.

---

## 🚀 2. Action Plan (실행 지침 및 Phase)

### Phase 1: PoC (현재 단계 - 모의 검증)
- **비용:** 0원 (기존 메인 Mac 사용)
- **워크플로우:** `run_factory.py`에서 `init_expo_app.sh` 서브에이전트가 호출되어 `workspace/` 내부를 지웠다 쓰며 Expo 스캐폴딩 및 `playwright` 웹(#app-root) 테스트로 컴포넌트를 모의 생성/수정/파기하는 루프까지만 유지.
- **안전 규칙:** CLI에서 Expo 배포 테스트 수행 시, 클라우드 연결 전 로컬 Web 렌더링 또는 Mock Export 빌드로 터미널 인터랙션 빙결(정지)을 예방.

### Phase 2: Agent Box 분리 (Daemonization)
- **트리거 시점:** 첫 번째 데모의 수익 발생 파이프라인 입증 완료, 혹은 메인 PC 리소스 점유가 업무 효율에 간섭(방해)을 주기 시작하는 즉시 전환.
- **도입 장비:** 엔트리 Mac Mini 기본형. 모니터 없는 헤드리스(Headless) 세팅.
- **동작 방식:** 팩토리 스크립트를 Linux/macOS 데몬(Daemon, systemd/launchd)으로 24시간 백그라운드로 돌려, 시장 파악 ➔ 자동 Expo 로직 패치 ➔ 자율 결함 QA 루틴 달성.

### Phase 3: Zero-Touch Continuous Deployment (배포 자동화 고도화)
- **Fastlane & EAS 연결:** 에이전트 Box의 권한을 열어, 팩토리가 스스로 `eas build --platform ios` 및 `fastlane deliver`을 터미널에서 구동하여 앱마켓 베타(TestFlight) 런칭까지 완전히 자율(Autonomous DevOps)로 해결하도록 플러그인 생태계를 완성.

---
>결론적으로 **전용 Hardware (Mac Mini) 구성은, 단순한 보조 장비 도입이 아니라 CLI 기반 자율 에이전트들의 권한(YOLO)을 100% 해금(Unleash)하여 24시간 수익 공장을 돌리기 위한 가장 SOTA(State-of-The-Art)적 필수 안전장치**입니다.
