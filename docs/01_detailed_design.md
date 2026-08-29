# 전도폭발 JUST EE 훈련 마스터 상세 설계서 (Detailed Design Document)

**문서 버전:** v2.2 (보안 3대 방안 연동 완료 / 2026-08-29 코드 대조 동기화)  
**작성일:** 2026-08-29  
**최종 검증:** 2026-08-29 — 실제 소스·데이터와 1:1 대조 완료 (`flutter analyze` 무결점, `flutter test` 30개 통과)  
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
│     3. ScriptureDeckScreen (핵심 8구절 암송 덱 & 빈칸 퀴즈)            │
│     4. VoiceExamScreen (시작 문두 3/4/5단어 제시 ➔ 7대 연계 완주 시험)  │
│     5. SettingsScreen (보안 라이선스 관리, TTS 보이스/톤, 대본 편집)    │
├────────────────────────────────────────────────────────────────────────┤
│                       State Management (Provider)                      │
│   - LicenseService        - StudyProvider                              │
│   - QuickTriggerProvider  - ScriptureProvider                          │
│   - VoiceExamProvider     - ScriptManageProvider                       │
│   (main.dart MultiProvider에 등록된 6종이 전부이며 그 외 Provider 없음) │
├────────────────────────────────────────────────────────────────────────┤
│                       Domain Layer (Business Logic)                    │
│   - LicenseService (기기 UUID 발급, SHA-256 PIN 검증, 원격 킬스위치)   │
│   - RandomExamEngine (7대 연계 출제 모드 & 3/4/5단어 문두 힌트 추출)    │
│   - ScoringEngine (Myers Diff & 키워드 가중치 채점 & 구어체 정규화)     │
│   - KoreanTextNormalizer (간투사 필터, 한글 수사 ➔ 아라비아 숫자 통일) │
│   - QuickTriggerEngine (난이도별 1s/2s/3s 타이머 & 선두 단어 추출)     │
│   - TransitionSentenceEngine (6대 대지 전환문장 무결성 검증)           │
│   - ScriptureDeckEngine (핵심 8구절 카드 & 빈칸 퀴즈 마스킹 데이터)     │
│   - DeviceHelperService (단말 기종/OS 정보 수집 ➔ 텔레메트리 전송)     │
├────────────────────────────────────────────────────────────────────────┤
│                    Infrastructure / Service Layer                      │
│   - Google Apps Script Webhook (Google Sheets 기반 원격 차단/승인 DB)  │
│   - TTSService (flutter_tts: 배속/피치 조절, 음절 안전 중첩 스크롤)    │
│   - STTService (speech_to_text: 장기 연속 수음 세그먼트 스티칭)        │
│   - ScriptRepository (8대 챕터 40개 문장 관리 & TXT 일괄 임포트)       │
│   - 시험 기록/오답 노트 로컬 저장 (실전시험·순발력 결과 누적)          │
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
  - 최초 앱 설치 시 `EE-XXXX-XXXX-XXXX` 형태의 기기 고유 UUID를 `Random.secure()`로 영구 생성.
  - 활성화 화면에서 **훈련생 성명 · 소속 교회 · 마스터 인증키** 3개 항목을 모두 입력해야 활성화.
  - 마스터 인증키는 `LicenseService._masterPins`에 복수(현재 4종) 내장되어 있고 대소문자·하이픈 차이를 무시하고 대조하며, 내장 키와 일치하지 않으면 SHA-256 해시로 원격 검증 경로를 시도.
  - **실제 인증키 값은 본 문서를 포함한 어떤 문서에도 기재하지 않습니다.** (문서가 유출되면 PIN 게이트가 무력화되므로, 훈련생 안내 시에도 개별 발급 형태로만 전달)

* **⚠️ 현재 구현의 알려진 한계 (2026-08-29 확인)**:
  - 활성화 상태(`just_ee_license_status`)와 입력된 인증키는 `SharedPreferences`에 **평문 문자열로 저장**됩니다. 암호화 저장이 아니므로, 루팅 단말에서는 값을 읽거나 위조할 수 있습니다.
  - 오프라인 동작(최초 1회 인증 후 인터넷 없이 사용)은 이 평문 로컬 상태에 근거합니다.
  - 강화가 필요하면 `flutter_secure_storage` 도입 또는 상태 값 서명(HMAC) 검증을 추가해야 합니다.

### 2.3 📧 방안 4: 신규 기기 실시간 텔레메트리 알림
* **작동 메커니즘**:
  - 새로운 기기에서 인증키가 입력되어 활성화될 때, Google Apps Script가 개발자 이메일(`xhpark@naver.com`)로 신규 기기 활성화 통보 메일을 즉시 발송.
  - 전송 데이터: 기기 UUID, 훈련생 성명, 입력 PIN, 기종 및 OS 버전, 활성화 일시.

---

## 3. 대본 데이터 구조 (Script Data Structure)

* **원본 데이터**: `data/just_ee_data.json` (pubspec `assets`에 등록, `version: 2.1`)
* **로드 경로**: `ScriptRepository.loadSections()` → JSON 8개 섹션 파싱 → 사용자 커스텀 문장/개인 간증/교회명 오버라이드 병합 → 메모리 캐시
* **총 문장 수**: **40개** (문서상 "38문장" 표기는 2026-08-29 실측으로 정정)

| 섹션 ID | 챕터명 | 문장 수 |
| :--- | :--- | :---: |
| `intro` | 1. 서론 (Introduction) | 6 |
| `grace` | 2.1 은혜 (Grace) | 4 |
| `humanity` | 2.2 인간 (Humanity) | 5 |
| `god` | 2.3 하나님 (God) | 4 |
| `christ` | 2.4 예수 그리스도 (Jesus Christ) | 5 |
| `faith` | 2.5 믿음 (Faith) | 4 |
| `commitment` | 3. 결신 (Commitment) | 5 |
| `follow_up` | 4. 즉석 양육 (Immediate Follow-up) | 7 |
| **합계** | | **40** |

### 3.1 성경 암송 덱 (8구절)

`ScriptureDeckEngine.scriptures`에 하드코딩된 8개 카드입니다. 2026-08-29 커밋 `8eeaf59`에서 본문에 등장하지 않는 3구절(롬 6:23, 마 5:48, 요 1:1)을 제거하여 실제 복음 제시 전문과 일치시켰습니다.

| # | 대지 | 성경 구절 |
| :--- | :--- | :--- |
| 1 | 1. 서론 (성경 기록 목적) | 요한일서 5:13 |
| 2 | 2.1 은혜 | 에베소서 2:8-9 |
| 3 | 2.2 인간 | 로마서 3:23 |
| 4 | 2.3 하나님 (사랑) | 요한일서 4:8b |
| 5 | 2.3 하나님 (공의) | 출애굽기 34:7b |
| 6 | 2.4 예수 그리스도 | 이사야 53:6 |
| 7 | 2.5 믿음 | 사도행전 16:31 |
| 8 | 3. 결신 / 구원의 확신 | 요한복음 6:47 |

### 3.2 실전시험 출제 엔진

`RandomExamEngine.generate()`는 7대 모드를 지원하며, 각 모드는 **고정된 문항 은행이 아니라 대본 데이터에서 매번 무작위로 1문항을 생성**합니다.

* `transitionChain` / `illustrationChain` / `scriptureChain` / `introAndCommitChain` / `followUpChain`: 해당 카테고리에서 1문항 즉석 생성
* `randomMix`: 위 5개 생성기 중 하나를 무작위 선택
* `fullSequential`: 전 섹션을 이어붙인 40문장 완주 1문항

---

## 4. 2026-08-29 정리 내역 (Dead Code Removal)

진입점이 없어 실행 불가능했던 즉석 양육 특화 화면 계열을 제거했습니다. 자세한 배경과 복구 방법은 [05_ai_handoff_log.md](05_ai_handoff_log.md)를 참고하십시오.

* 삭제: `lib/screens/follow_up_master_screen.dart`, `lib/providers/follow_up_provider.dart`, `lib/services/follow_up_engine.dart`, `test/follow_up_engine_test.dart`
* 삭제: `ScriptRepository.resetToDefault()`, `ScriptManageProvider.resetAll()` (설정 화면의 "교재 기본 대본 복원" UI가 커밋 `93fd9eb`에서 영구 제거되어 호출부가 사라진 잔재)
