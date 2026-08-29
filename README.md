# ✝️ 전도폭발 JUST EE 훈련 마스터 (Evangelism Explosion Personal Training System)

[![Flutter](https://img.shields.io/badge/Flutter-3.44.0-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12.0-0175C2?logo=dart)](https://dart.dev)
[![Tests](https://img.shields.io/badge/Tests-30%20Passed-brightgreen)](docs/02_module_test_specs.md)
[![License](https://img.shields.io/badge/Security-KillSwitch%20%2B%20PIN%20Active-success)](README.md)

전도폭발(EE International) 복음 제시 전문(1~8대 대지 40개 문장)의 **완벽한 암송과 실전 1:1 구두 훈련 역량 강화**를 위해 설계된 지능형 모바일 트레이닝 시스템입니다.

---

## 🛡️ 모바일 보안 및 비인가 복제 방지 시스템 (1, 2, 4 방안 탑재)

1. **원격 킬 스위치 (Remote Kill-Switch)**: 개발자의 구글 시트 관리 목록에서 `BLOCKED`로 전환 시 비인가 단말기 즉시 전면 차단.
2. **마스터 인증키 (Activation PIN 게이트)**: 최초 설치 시 훈련생 성명·소속 교회와 함께 개발자 발급 마스터 인증키 입력 필수. (인증키 실제 값은 소스 코드와 개발자만 보유하며, 문서에는 공개하지 않습니다.)
3. **신규 기기 실시간 텔레메트리 통보**: 새 기기 활성화 시 개발자 이메일(`xhpark@naver.com`)로 기기 정보 자동 전송.

---

## 🌟 핵심 기능 및 5대 탭 구성

1. **🎧 1. 학습/청취 (Study & Listen)**
   * 0.8x ~ 2.5x 속도 가변 TTS 고음질 음성 재생.
   * 4대 반복 재생 모드 (챕터 무한반복, 챕터 1회, 1문장 무한반복, 전체 1~8 완주).
   * 🖐️ 5손가락 복음 개요(Hand Outline: 은혜, 인간, 하나님, 그리스도, 믿음) 1:1 터치 동기화.
   * 180자 이상 긴 예화/기도문 발화 진행 시 자동 스크롤 추적.
   * 👁️ 가림막(블라인드) 자가 점검 모드.

2. **⚡ 2. 순발력/전환 (Quick Trigger & Transitions)**
   * 초급(5단어/3초), 중급(4단어/2초), 고급(3단어/1초) 실시간 STT 순발력 훈련.
   * 반응 속도(초) 기반 ⚡ 순발력 점수 + 🎯 Myers Diff 정확성 점수 듀얼 성적표.
   * 🔗 6대 대지 전환문장 집중 마스터 전용 덱.

3. **📖 3. 성경덱 (Scripture Deck)**
   * 전도폭발 8대 핵심 성경 구절 암송 카드 (요한일서 5:13, 에베소서 2:8-9, 로마서 3:23, 요한일서 4:8b, 출애굽기 34:7b, 이사야 53:6, 사도행전 16:31, 요한복음 6:47).
   * 구절 개별 TTS 음성 듣기 및 `[ ___ ]` 빈칸 퀴즈 모드.

4. **🎙️ 4. 실전시험 (Real Voice Exam)**
   * 7대 실전 시험 모드 (전환 ➔ 다음 단락 연계, 예화 집중 완주, 성경 구절 암송, 서론/결신 문답, 즉석 양육 항목별, 무작위 모의고사, 전체 전문 100% 완주).
   * 시작 문두(Lead-in Trigger) 3단어/4단어/5단어 가변 힌트 제공.
   * STT 장기 연속 수음 세그먼트 스티칭 엔진 탑재.
   * Myers Diff 기반 색상 분석 리포트 (🟢 일치 / 🔴 누락 / 🟡 변형).

5. **⚙️ 5. 설정 (Settings & Security)**
   * 기기 고유 코드(Device UUID) 확인 및 원격 승인 동기화.
   * 순수 한국어 TTS 보이스 선별 목록에서 목소리(Voice) 선택.
   * 음높이(Tone/Pitch) 슬라이더 및 3대 원터치 톤 프리셋(차분한 저음 / 표준 톤 / 밝은 고음).
   * 8대 챕터별 문장 개별 수정 및 TXT 전문 일괄 임포트/반영.
   * 개인 간증(서론 1.2) 및 소속 교회명 맞춤 저장.

---

## 📚 프로젝트 문서 목록

* **[📖 쉬운 앱 사용 설명서](docs/04_user_guide.md)**: 단계별 사용법 및 FAQ
* **[📐 시스템 상세 설계서 v2.1](docs/01_detailed_design.md)**: 보안 시스템, 아키텍처, 8대 챕터 매핑
* **[🧪 단위 및 모듈 테스트 명세서](docs/02_module_test_specs.md)**: 33개 단위/위젯 테스트 시나리오 및 통과 내역
* **[📋 통합 테스트 및 실기기 검증 계획서](docs/03_integration_test_plan.md)**: Galaxy S24 Ultra E2E 검증
* **[⚙️ 구글 앱스 스크립트 백엔드 코드](scripts/google_apps_script_backend.js)**: 구글 시트 배포용 소스
* **[🤝 AI 협업 인수인계 기록](docs/05_ai_handoff_log.md)**: 코드 현황·문서 동기화 이력 (Antigravity 등 타 AI 에이전트용)
* **[🤖 AI 에이전트 작업 규칙](AGENTS.md)**: 저장소 공통 규칙 및 금지 사항

---

## ⚖️ 저작권 및 개발자 정보

* **복음 제시 전문 텍스트 및 훈련 체계 저작권**: 사단법인 한국전도폭발본부 (Evangelism Explosion International)
* **애플리케이션 아키텍처 및 소프트웨어 소유권**: 개발자 박상환 (`xhpark@naver.com`)
* **이용 규정**: 본 애플리케이션은 개인 훈련생의 순수한 복음 암송 및 구두 훈련 목적으로만 사용 가능하며, 무단 복제, 상업적 이용 및 제3자 배포를 금지합니다.
