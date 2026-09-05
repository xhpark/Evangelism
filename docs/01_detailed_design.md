# 전도폭발 JUST EE 훈련 마스터 상세 설계서 (Detailed Design Document)

**문서 버전:** v2.5 (2026-09-02 활성화 호환성 및 실서버 검증 반영)
**작성일:** 2026-08-29  
**최종 검증:** 2026-09-02 — 앱 `1.0.1+2`, `flutter analyze` 0건, `flutter test` 48개 통과, 라인 커버리지 47.0%, release APK 실기기 설치·활성화 성공
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
│   - LicenseActivationScreen (기기 코드 & 일회용 활성화 코드 게이트)   │
│   - BlockedScreen (원격 킬 스위치 가동 시 비인가 단말기 접근 차단 화면)  │
│   - MainNavigationScreen (5대 핵심 탭 네비게이션)                      │
│     1. StudyScreen (TTS 0.8x~2.0x 배속, 4대 재생모드, 5손가락 연동)     │
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
│   - LicenseService (기기 토큰 보안 저장, 서버 승인, 원격 킬스위치)    │
│   - RandomExamEngine (7대 연계 출제 모드 & 3/4/5단어 문두 힌트 추출)    │
│   - ScoringEngine (어절 대조 & 키워드 가중치 채점, 긴 지문은 아이솔레이트) │
│   - KoreanTextNormalizer (간투사 필터, 한글 수사 ➔ 아라비아 숫자 통일) │
│   - QuickTriggerEngine (난이도별 1s/2s/3s 타이머 & 선두 단어 추출)     │
│   - TransitionSentenceEngine (6대 대지 전환문장 무결성 검증)           │
│   - ScriptureDeckEngine (핵심 8구절 카드 & 빈칸 퀴즈 마스킹 데이터)     │
│   - DeviceHelperService (단말 기종/OS 정보 수집 ➔ 텔레메트리 전송)     │
├────────────────────────────────────────────────────────────────────────┤
│                    Infrastructure / Service Layer                      │
│   - Google Apps Script Webhook (Google Sheets 기반 원격 차단/승인 DB)  │
│   - TTSService (flutter_tts: 배속/피치 조절, 음절 안전 중첩 스크롤)    │
│   - STTService (싱글턴, 침묵 시 자동 재개 스티칭, 한국어 로케일 고정)   │
│   - ScriptRepository (8대 챕터 40개 문장 관리 & TXT 일괄 임포트)       │
│   - 시험 기록/오답 노트 로컬 저장 (실전시험·순발력 결과 누적)          │
│   - Secure Storage(기기 토큰) / SharedPreferences(사용자 대본·기록)   │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. 라이선스 보안 설계

### 2.1 일회용 코드와 기기 토큰

* 최초 실행 시 `Random.secure()`로 `EE-XXXX-XXXX-XXXX-XXXX` 기기 코드를 생성합니다.
* 1.0.0 이하 설치에 남아 있는 3그룹 기기 코드는 사용자 학습 데이터를 지우지 않고 임의의 마지막 그룹을 붙여 4그룹으로 한 번만 마이그레이션합니다. 서버 코드도 재배포 시 3·4그룹을 모두 허용합니다.
* 관리자는 private `activation_codes` 시트에서 16자리 일회용 코드를 생성합니다. `createActivationCodes(count)`는 1~100개를 한 번에 만들 수 있지만 Apps Script 편집기의 무인수 실행은 기본 1개를 생성합니다. 서버가 `UNUSED` 상태를 확인하고 기기 등록과 코드 소진을 같은 스크립트 잠금 안에서 처리합니다.
* 승인 시 서버가 고엔트로피 기기 토큰을 반환합니다. 앱은 토큰을 `flutter_secure_storage`에 저장하고, 서버 시트에는 SHA-256 해시만 보관합니다.
* 소스에는 활성화 코드, 공유 시크릿, 배포 URL을 넣지 않습니다. URL은 빌드 시 `--dart-define=LICENSE_API_URL=...`로 주입합니다.
* 이전 방식으로 활성화됐지만 보안 토큰이 없는 설치는 대본·간증·시험 기록을 보존한 채 재활성화를 요구합니다.
* 서버 `DENIED`만 코드 거부로 표시하고, 서버 `ERROR`나 토큰 없는 비정상 승인 응답은 별도 서버 처리 오류로 안내합니다.

### 2.2 원격 승인과 차단

* 활성 기기는 앱 시작, 포그라운드 복귀, 사용 중 5분 간격으로 `device_id`와 `device_token`을 POST합니다.
* `BLOCKED`/`REVOKED` 응답은 즉시 `BlockedScreen`으로 전환합니다. `DENIED`/`UNREGISTERED`는 토큰을 삭제하고 활성화 화면으로 전환합니다.
* 네트워크 오류나 서버 미설정은 승인 성공으로 표시하지 않지만, 일시적 통신 실패만으로 기존 로컬 승인을 삭제하지는 않습니다.
* 리디렉션은 HTTPS의 `script.google.com` 및 Google 사용자 콘텐츠 호스트로만 제한합니다.

### 2.3 개인정보와 백업 경계

* 라이선스 서버 전송 항목은 기기 코드, 성명, 소속, OS/버전, 앱 버전입니다.
* 개인 간증, 수정 대본, 음성인식 결과, 시험 기록은 기기 로컬에만 저장하며 라이선스 서버로 전송하지 않습니다.
* Welcome 화면에서 저작권/면책 동의와 개인정보 수집·이용 동의를 각각 필수로 받습니다.
* Android 백업은 `allowBackup=false`와 데이터 추출 규칙으로 차단합니다.

### 2.4 서버 시트 안전성

* 활성화와 상태 확인은 `LockService`로 직렬화하고, 조회는 전체 시트 순회 대신 `TextFinder`를 사용합니다.
* 사용자 입력이 `=`, `+`, `-`, `@`로 시작하면 시트 수식으로 실행되지 않도록 문자열 처리합니다.
* 서버 예외 원문은 클라이언트에 반환하지 않습니다.
* 배포 전 GET health 응답의 `protocol=device_token_v2`를 확인해 구형 서버나 잘못된 배포 URL 연결을 차단합니다.
* `scripts/google_apps_script_backend.test.js`가 Apps Script API를 모사해 코드 소진, 재사용 거부, 토큰 해시, 차단/해제, 수식 주입 방지를 CI에서 검증합니다.

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

`RandomExamEngine.generateQuestion()`는 6대 모드를 지원하며, 각 모드는 **고정된 문항 은행이 아니라 대본 데이터에서 매번 무작위로 1문항을 생성**합니다. (순수 성경 구절 암송은 실전 특성에 맞춰 제외)

* `transitionChain` / `illustrationChain` / `introAndCommitChain` / `followUpChain`: 해당 카테고리에서 1문항 즉석 생성
* `randomMix`: 위 4개 생성기 중 하나를 무작위 선택
* `fullSequential`: 전 섹션 중 순수 성경 구절 6개를 제외한 34문장 완주 1문항

---

## 4. 2026-08-29 정리 내역 (Dead Code Removal)

진입점이 없어 실행 불가능했던 즉석 양육 특화 화면 계열을 제거했습니다. 자세한 배경과 복구 방법은 [05_ai_handoff_log.md](05_ai_handoff_log.md)를 참고하십시오.

* 삭제: `lib/screens/follow_up_master_screen.dart`, `lib/providers/follow_up_provider.dart`, `lib/services/follow_up_engine.dart`, `test/follow_up_engine_test.dart`
* 삭제: `ScriptRepository.resetToDefault()`, `ScriptManageProvider.resetAll()` (설정 화면의 "교재 기본 대본 복원" UI가 커밋 `93fd9eb`에서 영구 제거되어 호출부가 사라진 잔재)
