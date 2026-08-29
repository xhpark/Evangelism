# 🤝 AI 협업 인수인계 기록 (AI Handoff Log)

> **이 문서의 목적**
> 이 저장소는 여러 AI 코딩 에이전트(Claude Code, Antigravity 등)가 번갈아 작업합니다.
> **어떤 AI든 이 저장소에서 작업을 시작하기 전에 이 문서를 먼저 읽으십시오.**
> 코드만 봐서는 알 수 없는 "왜 이렇게 되어 있는가"와, 이미 의도적으로 제거된 기능을
> 되살리지 않도록 하는 금지 사항이 기록되어 있습니다.

---

## 0. 프로젝트 한눈에 보기

| 항목 | 값 |
| :--- | :--- |
| 프로젝트 | 전도폭발 JUST EE 훈련 마스터 (Flutter / Android) |
| 경로 | `d:\proj\Evangelism` |
| 상태 관리 | Provider (MVVM), `lib/main.dart`의 `MultiProvider`에 **6종** 등록 |
| 대본 원본 | `data/just_ee_data.json` — 8개 섹션 / **총 40문장** |
| 성경 암송 덱 | `lib/services/scripture_deck_engine.dart` — **8구절 하드코딩** |
| 전환문장 6개 | `data/just_ee_data.json`의 `transition_text` 필드 (하드코딩 아님) |
| 검증 명령 | `flutter analyze` (경고 0건 유지) / `flutter test` (**42개** 통과) |
| 문서 | `README.md`, `docs/01`~`docs/04`, 그리고 본 문서 |

---

## 1. 2026-08-29 작업 기록 — 문서·코드 동기화 및 죽은 코드 제거

**작업 주체:** Claude Code (Opus 5) / **의뢰인:** 박상환
**작업 시작 시점의 HEAD:** `ad386e3` (TTS 한국어 보이스·톤 프리셋 수정)

### 1.1 배경

최근 3개 커밋(`8eeaf59` 성경덱 3구절 제거, `93fd9eb` 대본 복원 버튼 제거, `ad386e3` TTS 톤 프리셋 추가)이
문서에 반영되지 않아, 문서와 실제 코드가 9개 항목에서 어긋나 있었습니다. 문서를 코드 기준으로 맞추고,
그 과정에서 드러난 미연결(dead) 코드를 정리했습니다.

### 1.2 삭제한 코드 — ⚠️ 되살리지 마십시오

| 삭제 대상 | 줄 수 | 삭제 사유 |
| :--- | :---: | :--- |
| `lib/screens/follow_up_master_screen.dart` | 546 | 즉석 양육 4단계 특화 훈련 화면. **v2.0 최초 커밋(`2bae17a`)부터 어떤 화면에서도 참조된 적이 없는** 진입 불가 화면이었음. |
| `lib/providers/follow_up_provider.dart` | 139 | 위 화면 전용 Provider. 화면 삭제로 소비자 소멸. `main.dart` 등록도 함께 제거. |
| `lib/services/follow_up_engine.dart` | 83 | 위 Provider 전용 엔진. 프로덕션 참조 없음. |
| `test/follow_up_engine_test.dart` | 테스트 3개 | 삭제된 엔진 전용 테스트 (TS-FOLL-001/002/004). |
| `ScriptRepository.resetToDefault()` | 7 | 설정 화면의 "교재 기본 대본으로 전체 복원" UI가 커밋 `93fd9eb`에서 **영구 제거**되어 호출부가 사라진 잔재. |
| `ScriptManageProvider.resetAll()` | 5 | 위 메서드의 유일한 호출자. |
| `test/script_edit_propagation_test.dart`의 복원 검증 단계 | 6 | 위 기능 제거에 따른 정리. 문장 수정 전파·채점 반영 검증 본체는 그대로 유지. |

> **판단이 필요했던 지점:** 즉석 양육 화면은 미완성 잔재가 아니라 **완성돼 있으나 진입로만 없는 546줄 기능**이었습니다.
> 보존 / 네비게이션 연결 / 전체 삭제 세 가지를 의뢰인에게 제시했고, **의뢰인이 "체인 전체 삭제"를 선택**하여 제거했습니다.
> 즉석 양육 훈련 자체는 사라지지 않습니다 — 학습 탭의 `follow_up` 챕터(7문장)와 실전시험의 `followUpChain` 모드로 계속 훈련 가능합니다.
>
> **복구 방법 (되살릴 필요가 생겼을 때만):**
> ```bash
> git checkout ad386e3 -- lib/screens/follow_up_master_screen.dart lib/providers/follow_up_provider.dart lib/services/follow_up_engine.dart test/follow_up_engine_test.dart
> ```
> 복구 시 `main.dart`에 `FollowUpProvider` 재등록 + 실제 진입 버튼 연결이 반드시 필요합니다.

### 1.3 수정한 코드

* `lib/services/random_exam_engine.dart:110` — 전체 완주 시험 안내 문구의 `전체 전문(38문장)` → **`(40문장)`**.
  `data/just_ee_data.json`의 실제 문장 수(6+4+5+4+5+4+5+7 = 40)와 어긋난 사용자 노출 문구였습니다.

### 1.4 문서에서 바로잡은 불일치 9건

| # | 문서 주장 | 실제 코드 | 조치 |
| :---: | :--- | :--- | :--- |
| 1 | 성경덱 9구절 | 8구절 (`scripture_deck_engine.dart`) | README·01·03·04 전부 8구절로 수정 + 구절 표 추가 |
| 2 | 전문 38문장 | 40문장 (`just_ee_data.json`) | 문서 및 앱 내 문구 40으로 통일, 섹션별 문장 수 표 신설 |
| 3 | "교재 기본 대본 복원" 기능 | 커밋 `93fd9eb`에서 제거됨 | README에서 삭제, 사용설명서 FAQ에 제거 사유 안내 추가 |
| 4 | 인증 = PIN만 입력 | 성명·소속 교회·PIN **3개** 필수 | 사용설명서 1.2 재작성 |
| 5 | TTS 톤 프리셋 미기재 | 3대 프리셋 존재 (`ad386e3`) | README·03·04에 반영 |
| 6 | 테스트 11개 파일 33개 | (삭제 후) 11개 파일 30개 | 02 명세서 갱신 + 폐기 테스트 표 신설 |
| 7 | 아키텍처 목록 누락 | `ScriptureDeckEngine`, `DeviceHelperService` 누락 | 01 설계서 계층도 보강 |
| 8 | "28개 전 문항 중 랜덤" | 고정 문항 은행 없음, 매번 즉석 생성 | 04 설명서에서 정확한 동작으로 수정 |
| 9 | 시험 기록/오답 저장 미기재 | `just_ee_exam_history`, `just_ee_mistakes` 사용 중 | 01 설계서 인프라 계층에 명시 |

### 1.5 보안 문서 정정 (2건) — 중요

1. **마스터 인증키 값을 모든 문서에서 삭제했습니다.**
   기존 README·설계서·사용설명서가 실제 유효 인증키(`LicenseService._masterPins`의 4개 중 하나)를 "예시"로 노출하고 있었습니다.
   문서가 저장소·메일·메신저로 유출되면 PIN 게이트가 그대로 무력화됩니다.
   **앞으로 어떤 AI도 문서·커밋 메시지·이슈에 실제 인증키 값을 기재하지 마십시오.**
2. **설계서의 "안전하게 암호화 보관" 표현을 사실대로 정정했습니다.**
   `LicenseService`는 활성화 상태와 입력 인증키를 `SharedPreferences`에 **평문**으로 저장합니다
   (SHA-256은 원격 검증 경로에만 사용). 01 설계서 2.2에 "알려진 한계"로 명시하고,
   강화 방향(`flutter_secure_storage` 또는 상태값 HMAC 서명)을 적어 두었습니다.

### 1.6 검증 결과

```
flutter analyze  →  No issues found!
flutter test     →  +30: All tests passed!
```

**실기기 검증은 수행하지 않았습니다.** 이번 작업은 문서 동기화와 죽은 코드 제거이며, Galaxy S24 Ultra 실기기 확인은 하지 않았습니다.
특히 커밋 `ad386e3`의 TTS 보이스/톤 프리셋은 03 통합테스트 계획서에 `IT-08 / 미검증`으로 새로 등록해 두었으니,
실기기에서 음성 출력을 확인한 뒤 담당자가 PASS로 갱신해야 합니다.

---

## 2. 2026-08-29 작업 기록 (2차) — 전면 점검 및 보안·안정성 보강

**작업 주체:** Claude Code (Opus 5) / **의뢰인:** 박상환
**작업 시작 시점의 HEAD:** `caa7d90` (1차 문서 동기화 커밋)
**의뢰 내용:** 앱 전반을 안정성·운영성·연동성 관점에서 점검하고, 제안 후 승인받아 적용할 것.

### 2.1 점검 방법

코드 7,872줄 + Android 설정 + Apps Script 백엔드를 통독하고, 추정으로 남을 항목은 임시 측정 코드를 작성해 실측했다(측정 후 삭제). 실측으로 확인한 값:

* 인증키 우회: `JUSTABCD`, `JUST1234`, `JUSTINBIEBER`, `JUST-XXXX-YYYY` 모두 활성화 통과
* 전체 완주 채점 소요: 동일 발화 19ms / 절반만 발화 **1,997ms** (원문 7,736자, UI 스레드 블로킹)
* 정규화 부작용: `"이 사장님은 ... 일절 관여하지"` → `"이 4장님은 ... 1절 관여하지"`
* 전환문장: 엔진 하드코딩 6개 vs 데이터 `is_transition` 5개, 6번째는 문장 내용 자체가 상이

### 2.2 의뢰인이 결정한 정책 (임의로 바꾸지 말 것)

| 항목 | 결정 |
| :--- | :--- |
| 적용 범위 | S1(보안)~S5(운영) **전부 적용** |
| 전환문장 정합 | 데이터에 `transition_text` 필드를 추가해 **단일 출처화** (엔진 하드코딩 제거) |
| 채점 엄격도 | **중간** — 조사·어미 차이는 정답, 다른 단어는 오답 |
| 저작권 동의 게이트 | **매 실행마다 유지** (1회 저장으로 바꾸지 말 것) |

### 2.3 보안 (S1)

| 조치 | 파일 |
| :--- | :--- |
| `"JUST"` 접두 인증키 우회 분기 삭제 — 내장 키 정확 일치만 허용 | `lib/services/license_service.dart` |
| 요청 서명 `sig = sha256("<UUID>\|<공유시크릿>")` 도입, 백엔드에서 검증 | 앱 `license_service.dart` + `scripts/google_apps_script_backend.js` |
| 백엔드가 `MASTER_PINS`를 실제로 검증 (이전에는 선언만 하고 미사용) | `scripts/google_apps_script_backend.js` |
| `LockService`, `getSheetByName("licenses")` 적용 (중복행·오시트 기록 방지) | 동상 |
| 웹훅 URL 변경에 마스터 인증키 재확인 게이트 + `https://...google.com` 형식 검증 | `lib/screens/settings_screen.dart` |
| `allowBackup="false"` + `data_extraction_rules.xml` (백업 복제 차단) | `android/app/src/main/...` |
| `UNREGISTERED` 응답 시 자가 재등록, 포그라운드 복귀마다 킬스위치 재확인, 사용 중 차단 시 즉시 차단 화면 | `license_service.dart`, `main_navigation_screen.dart` |

> ⚠️ **공유 시크릿을 바꾸려면 앱(`_sharedSecret`)과 Apps Script(`SHARED_SECRET`)를 함께 바꾸고 재배포해야 한다.**
> ⚠️ **사장님이 Apps Script를 시트에 다시 붙여넣고 재배포해야 백엔드 개정이 실제로 적용된다.**

### 2.4 기능 오작동 (S2)

* **전체 완주 재생 챕터 건너뜀**: `study_provider.dart`에서 루프 안에 `_selectedSectionIndex`를 먼저 대입해 `startIdx` 조건이 항상 참이던 버그 수정. 시작 챕터에만 `fromIndex`를 적용한다. (회귀 테스트 `TS-PLAY-001`)
* **STT 래퍼 싱글턴화**: `speech_to_text`는 싱글턴이고 `initialize()`가 최초 1회만 콜백을 등록하므로, 탭마다 래퍼를 만들면 나중 것이 상태 콜백을 못 받아 '인식 중'에서 멈췄다. `STTService`를 싱글턴으로 바꾸고 콜백을 **수음 시작 시점에 소유자가 주입**하는 구조로 변경.
* **장문 수음 자동 재개**: 침묵 4초로 인식기가 멈추면 지금까지의 결과에 이어서 자동 재개(`keepAlive`, 최대 60회). 문서가 홍보하던 "세그먼트 스티칭"이 실제로 동작하게 됐다.
* **한국어 로케일 고정**: `listen()`에 단말의 한국어 로케일을 지정 (이전에는 단말 기본 로케일).
* **전환문장 단일 출처화**: `TransitionSentenceEngine`을 `buildFromSections(sections)`로 재작성. 목록과 대본이 어긋나지 않는지 `TS-TRANS-002`가 검증한다.
* **대본 수정 전파**: 설정에서 문장 수정·간증 저장·TXT 일괄 반영 시 학습 탭뿐 아니라 순발력 덱(`refreshFromRepository`)과 실전시험 문항까지 갱신.
* **배속 표기 정합**: 안드로이드 `flutter_tts`가 값을 2배로 넘기는 점을 반영해 `_platformRate = 표시배속 / 2`로 단순화. 이전에는 1.0으로 잘려 2.5x가 실제 2.0x였다.
* **탭/백그라운드 전환 시 오디오 중재**: 탭 이동·앱 백그라운드 시 TTS 정지 + STT 취소.

### 2.5 안정성·성능 (S3)

* 긴 지문 채점을 `compute()` 아이솔레이트로 이전 (`ScoringEngine.calculateScoreAsync`, 임계값 800자). 채점 중 "채점 중입니다..." 표시.
* 시험 이력 상한 50건 (`ScriptRepository.maxExamHistory`) — 무제한 누적 시 저장할 때마다 전량 재직렬화되던 문제.
* 기동 실패 시 `StartupErrorApp` 안내 화면 (이전에는 흰 화면으로 종료).
* 마이크/인식 실패 사유를 한국어로 변환해 화면에 배너 노출 (`sttError`).
* 순발력 타이머 50ms → 100ms (초당 리빌드 20회 → 10회).
* 미사용 의존성 `permission_handler` 제거.

### 2.6 채점 품질 (S4)

* 부분 일치 규칙 교체: "앞 2글자만 겹치면 정답" → `ScoringEngine.isSameWordStem()` (조사 제거 후 어간 비교 + 접두 관계). `TS-SCORE-004`가 고정.
* 정규화기 재작성: 지시어 `그/이/저/아/에/막`을 간투사 목록에서 제외, 장/절 수사는 **어절 전체가 수사+장/절일 때만** 변환하고 `일절`·`사장` 등은 예외 처리. `십육`·`이십삼` 같은 조합 수사를 파서로 처리. `TS-NORM-004/005`가 고정.
* "Myers Diff" 표현을 실제 알고리즘(어절 lookahead 그리디 정렬)에 맞춰 코드 주석·문서·UI에서 정정.
* 순발력 반응시각을 음성 에너지 감지 시점 기준으로 잡고, UI에 "(음성 감지 기준)"으로 명시.

### 2.7 운영·배포 (S5)

* `android/key.properties`가 있으면 릴리스 키로 서명하고 없으면 경고 후 디버그 키 폴백 (`android/app/build.gradle.kts`). **배포용 APK를 만들기 전에 키스토어를 생성해야 한다.**
  ```
  keytool -genkey -v -keystore D:/keys/just-ee-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias just-ee
  ```
  그 뒤 `android/key.properties`에 `storeFile`, `storePassword`, `keyAlias`, `keyPassword`를 기입한다. 이 파일과 `.jks`는 `.gitignore`에 등록되어 있으니 **절대 커밋하지 말 것.**
* 텔레메트리 `app_version` 하드코딩 제거 → `LicenseService.appVersion` 상수 (pubspec의 version과 함께 갱신).
* GitHub Actions CI 추가 (`.github/workflows/flutter-ci.yml`): push/PR마다 `flutter analyze` + `flutter test`.
* `ocr_1.txt` 추적 해제(로컬 파일은 유지), `.gitignore`에 키·산출물 규칙 추가.

### 2.8 검증 결과

```
flutter analyze         →  No issues found!
flutter test            →  +42: All tests passed!   (14개 파일)
flutter build apk --debug →  √ Built buildpp\outputslutter-apkpp-debug.apk
```

**실기기 검증은 하지 않았다.** TTS 배속·STT 자동 재개·마이크 오류 안내·탭 전환 중재·원격 차단 즉시 반영은 에뮬레이터/단위 테스트로 확인할 수 없다.
`docs/03_integration_test_plan.md`에 `IT-08` ~ `IT-16`으로 **미검증** 상태를 명시해 두었으니, Galaxy S24 Ultra에서 확인한 뒤 PASS로 갱신할 것.

### 2.9 후속 수정 — 원격 승인 동기화가 조용히 실패하던 문제 (같은 날 야간)

재배포 후 "원격 승인 동기화"를 눌러도 관리 시트의 '최근 접속 일시'가 갱신되지 않는다는 보고로 추적한 결과, 백엔드가 아니라 **앱의 HTTP 타임아웃**이 원인이었다.

**실측 (Galaxy S24 Ultra 단말에서 직접 측정)**

| 요청 | 소요 시간 | 기존 제한 | 결과 |
| :--- | :--- | :--- | :--- |
| `check_status` GET (콜드 스타트) | **5,024ms** | 5초 | ❌ TimeoutException |
| `check_status` GET (웜) | 2,405ms | — | ✅ |
| `activate` POST | 1,346 ~ 2,593ms | 6초 | ✅ |

Apps Script 웹앱은 콜드 스타트 때 5초를 넘나든다. 기존 5초 제한이 정확히 그 경계였다.

**함께 확인한 사실**

* `package:http`의 POST는 Apps Script의 302 리다이렉트를 **따라가지 않는다**(dart:io는 GET/HEAD만 자동 추적). 다만 서버측 `doPost`는 리다이렉트 추적 여부와 무관하게 실행되므로 **등록 자체는 성공**한다. 검증 방법: 리다이렉트를 끄고 POST한 뒤 같은 기기를 조회하면 `APPROVED`가 나온다.
* 그 결과 앱은 서버 응답(인증키 거부 등)을 전혀 읽지 못하고 있었다.

**조치**

* 타임아웃을 `LicenseService._requestTimeout = 20초`로 통일 (GET·POST 공통).
* `_postFollowingRedirect()` 추가 — 302/303/307이면 Location을 GET으로 한 번 더 요청해 응답 본문을 읽는다.
* `_sendTelemetry()`가 `Future<bool>`을 반환해 등록 확인 여부를 알려주고, 자가 재등록 실패 시 동기화 메시지에 반영한다.
* 설정 탭의 [원격 승인 동기화]가 **로컬 상태가 아니라 서버 응답**을 표시하도록 수정 (`RemoteSyncResult`). 이전에는 통신 실패·서명 거부까지 "✅ 정상 확인"으로 보였다. 회귀 테스트 `TS-SEC-004/005`.

**⚠️ 다음 작업자를 위한 함정 두 가지**

1. **`flutter run`으로 단말 진단을 하지 말 것.** `flutter run`은 같은 패키지명으로 **디버그 빌드를 덮어써서** 릴리스 서명과 충돌하고, 결국 앱을 삭제해야 하므로 훈련생의 활성화·간증·대본이 모두 날아간다. 네트워크 진단은 PC에서 파이썬/curl로 하거나, 별도 패키지명의 시험용 앱으로 하라.
2. **Apps Script 응답 시간을 낙관하지 말 것.** 콜드 스타트가 5초를 넘는다. 새 엔드포인트를 추가할 때도 타임아웃은 15초 이상으로 잡아라.

---

## 3. 이 저장소에서 작업하는 AI를 위한 규칙

1. **문서와 코드가 다르면 코드가 정답입니다.** 단, 사용자 노출 문구(문장 수 등)가 데이터와 어긋나면 그것은 코드 버그이니 데이터 기준으로 고치십시오.
2. **되살리면 안 되는 기능**: 즉석 양육 마스터 화면 계열(§1.2), 대본 일괄 복원 버튼. 둘 다 의도적으로 제거되었습니다.
3. **문서에 실제 마스터 인증키·웹훅 비밀 값을 쓰지 마십시오.** (§1.5)
4. **숫자를 문서에 쓸 때는 반드시 실측하십시오.** 문장 수는 `data/just_ee_data.json`, 구절 수는 `scripture_deck_engine.dart`, 테스트 수는 `flutter test` 실행 결과가 근거입니다.
5. **작업을 마치면 `flutter analyze`와 `flutter test`를 모두 돌리고, 그 출력을 근거로만 "통과"를 주장하십시오.**
6. **코드를 바꿨으면 관련 문서(README, `docs/01`~`docs/04`)를 같은 작업 안에서 갱신하고, 이 문서에 새 절을 추가하십시오.**
7. 원문(복음 제시 전문) 텍스트는 사단법인 한국전도폭발본부 저작물입니다. 임의로 문구를 창작·윤색하지 마십시오.
8. **되돌리면 안 되는 보안 조치** (§2.3): 인증키 우회 분기 복원 금지, 웹훅 URL 게이트 제거 금지, `allowBackup="false"` 해제 금지, 요청 서명 검증 제거 금지. 회귀 테스트 `TS-SEC-001`이 우회 복원을 막고 있습니다.
9. **의뢰인이 정한 정책** (§2.2): 채점은 '중간' 엄격도, 저작권 동의 게이트는 매 실행 유지, 전환문장은 데이터 단일 출처. 바꾸려면 의뢰인 승인을 받으십시오.
10. **STT는 싱글턴입니다.** 탭마다 `STTService()`를 새로 만들지 마십시오(이미 factory로 같은 인스턴스가 반환됩니다). 콜백은 `startListening()` 호출 시 주입하는 방식만 사용하십시오.
11. **문장 수·구절 수 같은 숫자를 UI 문자열에 하드코딩하지 마십시오.** 데이터에서 세어 쓰십시오(과거 "38문장" 오류의 원인).
12. **실기기에서만 확인 가능한 항목은 문서에 '미검증'으로 남기십시오.** 확인하지 않은 것을 PASS로 적지 마십시오.
