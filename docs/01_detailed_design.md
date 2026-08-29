# 전도폭발 JUST EE 훈련 마스터 상세 설계서 (Detailed Design Document)

**문서 버전:** v2.1 (보안 3대 방안: 원격 킬스위치, 마스터 PIN 게이트, 신규기기 텔레메트리 연동 완료)  
**작성일:** 2026-08-29  
**프로젝트 위치:** `d:\proj\Evangelism`  
**개발 프레임워크:** Flutter 3.44.0 (Dart 3.12.0)  
**대상 플랫폼:** Android (Phone & Tablet)  
**개발자:** 박상환 (xhpark@naver.com)  
**원문 저작권:** 사단법인 한국전도폭발본부 (Evangelism Explosion International)

---

## 1. 시스템 아키텍처 (System Architecture)

본 앱은 유지보수성, 테스트 용이성, 모듈 간 결합도 최소화를 위해 **Clean Architecture + MVVM 패턴 (Provider)**을 채택합니다.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Presentation Layer (UI)                         │
│   - WelcomeTermsScreen (저작권 고지 & 면책 동의 진입 게이트)            │
│   - LicenseActivationScreen (기기 고유 UUID & 마스터 PIN 인증 게이트)  │
│   - BlockedScreen (원격 킬 스위치 가동 시 비인가 단말기 접근 차단 화면)  │
│   - MainNavigationScreen (5대 핵심 탭 네비게이션)                      │
│     1. StudyScreen (TTS 0.8x~2.5x 배속, 4대 재생모드, 5손가락 연동)     │
│     2. QuickTriggerScreen (1s/2s/3s 순발력 STT & 6대 전환문장 덱)      │
│     3. ScriptureDeckScreen (핵심 9구절 암송 덱 & 빈칸 퀴즈)            │
│     4. VoiceExamScreen (시작 문두 3/4/5단어 제시 ➔ 7대 연계 완주 시험)  │
│     5. SettingsScreen (보안 라이선스 관리, TTS 보이스/톤, 대본 편집)    │
├────────────────────────────────────────────────────────────────────────┤
│                       State Management (Provider)                      │
│   - LicenseService        - StudyProvider                              │
│   - QuickTriggerProvider  - ScriptureProvider                          │
│   - VoiceExamProvider     - ScriptManageProvider                       │
├────────────────────────────────────────────────────────────────────────┤
│                       Domain Layer (Business Logic)                    │
│   - LicenseService (기기 UUID 발급, SHA-256 PIN 검증, 원격 킬스위치)   │
│   - RandomExamEngine (7대 연계 출제 모드 & 3/4/5단어 문두 힌트 추출)    │
│   - ScoringEngine (Myers Diff & 키워드 가중치 채점 & 구어체 정규화)     │
│   - KoreanTextNormalizer (간투사 필터, 한글 수사 ➔ 아라비아 숫자 통일) │
│   - QuickTriggerEngine (난이도별 1s/2s/3s 타이머 & 선두 단어 추출)     │
│   - TransitionSentenceEngine (6대 대지 전환문장 무결성 검증)           │
│   - FollowUpEngine (양육 5손가락 성장 수단 & 4대 확신 문답)            │
├────────────────────────────────────────────────────────────────────────┤
│                    Infrastructure / Service Layer                      │
│   - Google Apps Script Webhook (Google Sheets 기반 원격 차단/승인 DB)  │
│   - TTSService (flutter_tts: 배속/피치 조절, 음절 안전 중첩 스크롤)    │
│   - STTService (speech_to_text: 장기 연속 수음 세그먼트 스티칭)        │
│   - ScriptRepository (8대 챕터 38개 문장 관리 & TXT 일괄 임포트/복원)  │
│   - SharedPreferences / File I/O (암호화 라이선스 및 사용자 대본 저장) │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. 보안 3대 해결방안 (1, 2, 4) 상세 설계

### 2.1 🛡️ 방안 1: 원격 킬 스위치 (Remote Kill-Switch)
* **작동 메커니즘**:
  - 앱 구동 시 백그라운드에서 개발자의 Google Apps Script Webhook(`?action=check_status&device_id=UUID`)을 조회.
  - 개발자가 구글 시트에서 특정 기기의 상태를 `BLOCKED` 또는 `REVOKED`로 변경하면, 앱은 즉시 `BlockedScreen`으로 전환되어 모든 기능이 잠김.
  - `BlockedScreen`에서는 차단 사유 안내 및 개발자(`xhpark@naver.com`) 문의 링크만 노출.

### 2.2 🔑 방안 2: 마스터 인증키 (Activation PIN 게이트)
* **작동 메커니즘**:
  - 최초 앱 설치 시 `EE-XXXX-XXXX-XXXX` 형태의 기기 고유 UUID를 영구 생성.
  - 개발자가 발급한 8자리 마스터 인증키(예: `JUST-EE2026`)를 입력해야만 활성화.
  - 활성화 상태는 로컬 `SharedPreferences`에 안전하게 암호화 보관되어 오프라인에서도 작동.

### 2.3 📧 방안 4: 신규 기기 실시간 텔레메트리 알림
* **작동 메커니즘**:
  - 새로운 기기에서 인증키가 입력되어 활성화될 때, Google Apps Script가 개발자 이메일(`xhpark@naver.com`)로 신규 기기 활성화 통보 메일을 즉시 발송.
  - 전송 데이터: 기기 UUID, 훈련생 성명, 입력 PIN, 기종 및 OS 버전, 활성화 일시.
