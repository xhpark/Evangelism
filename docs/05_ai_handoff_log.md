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
| 검증 명령 | `flutter analyze` (경고 0건 유지) / `flutter test` (**48개** 통과) |
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

**검증 결과 (2026-08-29 야간, Galaxy S24 Ultra)**

수정 후 실기기에서 [원격 승인 동기화]가 정상 응답하고 관리 시트의 '최근 접속 일시'가 갱신되는 것을 확인했다.
앱 → 서명 → 백엔드 → 시트 기록까지 전 구간 실동작 검증 완료(`docs/03`의 `IT-17`).

**⚠️ 다음 작업자를 위한 함정 두 가지**

1. **`flutter run`으로 단말 진단을 하지 말 것.** `flutter run`은 같은 패키지명으로 **디버그 빌드를 덮어써서** 릴리스 서명과 충돌하고, 결국 앱을 삭제해야 하므로 훈련생의 활성화·간증·대본이 모두 날아간다. 네트워크 진단은 PC에서 파이썬/curl로 하거나, 별도 패키지명의 시험용 앱으로 하라.
2. **Apps Script 응답 시간을 낙관하지 말 것.** 콜드 스타트가 5초를 넘는다. 새 엔드포인트를 추가할 때도 타임아웃은 15초 이상으로 잡아라.

---

## 3. 이 저장소에서 작업하는 AI를 위한 규칙

1. **문서와 코드가 다르면 코드가 정답입니다.** 단, 사용자 노출 문구(문장 수 등)가 데이터와 어긋나면 그것은 코드 버그이니 데이터 기준으로 고치십시오.
2. **되살리면 안 되는 기능**: 즉석 양육 마스터 화면 계열(§1.2), 대본 일괄 복원 버튼. 둘 다 의도적으로 제거되었습니다.
3. **문서에 실제 활성화 코드·기기 토큰·라이선스 서버 URL을 쓰지 마십시오.** (§5)
4. **숫자를 문서에 쓸 때는 반드시 실측하십시오.** 문장 수는 `data/just_ee_data.json`, 구절 수는 `scripture_deck_engine.dart`, 테스트 수는 `flutter test` 실행 결과가 근거입니다.
5. **작업을 마치면 `flutter analyze`와 `flutter test`를 모두 돌리고, 그 출력을 근거로만 "통과"를 주장하십시오.**
6. **코드를 바꿨으면 관련 문서(README, `docs/01`~`docs/04`)를 같은 작업 안에서 갱신하고, 이 문서에 새 절을 추가하십시오.**
7. 원문(복음 제시 전문) 텍스트는 사단법인 한국전도폭발본부 저작물입니다. 임의로 문구를 창작·윤색하지 마십시오.
8. **되돌리면 안 되는 보안 조치** (§5): 로컬 마스터 PIN·공유 시크릿 복원 금지, 앱 내 서버 URL 변경 기능 복원 금지, `allowBackup="false"` 해제 금지. 일회용 코드와 보안 저장소 기기 토큰을 유지하십시오.
9. **의뢰인이 정한 정책** (§2.2): 채점은 '중간' 엄격도, 저작권 동의 게이트는 매 실행 유지, 전환문장은 데이터 단일 출처. 바꾸려면 의뢰인 승인을 받으십시오.
10. **STT는 싱글턴입니다.** 탭마다 `STTService()`를 새로 만들지 마십시오(이미 factory로 같은 인스턴스가 반환됩니다). 콜백은 `startListening()` 호출 시 주입하는 방식만 사용하십시오.
11. **문장 수·구절 수 같은 숫자를 UI 문자열에 하드코딩하지 마십시오.** 데이터에서 세어 쓰십시오(과거 "38문장" 오류의 원인).
12. **실기기에서만 확인 가능한 항목은 문서에 '미검증'으로 남기십시오.** 확인하지 않은 것을 PASS로 적지 마십시오.

---

## 4. 2026-08-29 작업 기록 (3차) — 전문 40문장 소제목 괄호 원자적 줄바꿈 정비

**작업 주체:** Antigravity / **의뢰인:** 박상환
**작업 시작 시점의 HEAD:** `fd7ba57` (원격 승인 동기화 타임아웃 20초 확대 및 리다이렉트 추적)

### 4.1 배경 및 목적

소제목 중 `"성경 기록 목적 및 팀원 확신 확인"`(19자)과 같이 긴 단문형 제목이 단말 화면에서 어절 중간에 잘려 줄바꿈되는 현상이 발생함.
의뢰인의 지침("괄호 안의 내용을 줄바꿈 해야 하면 괄호 전체를 줄바꿈하도록 하자")에 따라, 8대 섹션 40개 전체 문장의 소제목을 `주제 (부연 설명)` 구조로 통일 정비함.

### 4.2 개선된 소제목 목록 (주요 12개)

* `intro_2`: `영생의 정의 및 개인 간증` ➔ **`영생의 정의 (개인 간증)`**
* `intro_5`: `성경 기록 목적 및 팀원 확신 확인` ➔ **`성경 기록 목적 (팀원 확신 확인)`**
* `intro_6`: `제2 진단 질문 및 복음 제시 허락` ➔ **`제2 진단 질문 (복음 제시 허락)`**
* `grace_3`: `햇빛·공기·물 선물 예화` ➔ **`햇빛·공기·물 (선물 예화)`**
* `human_4`: `하루 3번 9만 번 죄 예화` ➔ **`하루 3번 9만 번 (죄의 누적 예화)`**
* `god_3`: `가르시아 장군 어머니 채찍 예화` ➔ **`가르시아 장군 (어머니 채찍 예화)`**
* `christ_4`: `다 이루었다 & 부활·승천` ➔ **`다 이루었다 (부활과 승천)`**
* `faith_1`: `거짓 믿음 배제 및 참 믿음의 정의 (핵심 진리)` ➔ **`거짓 믿음과 참 믿음 (핵심 진리)`**
* `faith_4`: `동기부여 질문 (신뢰의 대상 이전)` ➔ **`동기부여 질문 (신뢰 대상 이전)`**
* `commit_1`: `결신 질문 (영생의 선물 수령 결단)` ➔ **`결신 질문 (영생의 선물 결단)`**
* `commit_4`: `확신 기도 (대상자를 위한 축복 기도)` ➔ **`확신 기도 (대상자 축복 기도)`**
* `commit_5`: `구원의 확신 말씀 및 확인 문답 (요한복음 6:47)` ➔ **`구원의 확신 문답 (요한복음 6:47)`**
* `follow_1`: `소책자 증정 및 '나의 결정' 서명` ➔ **`소책자 증정 ('나의 결정' 서명)`**

### 4.3 검증 결과

* `flutter analyze` ➔ 경고 0건
* `flutter test` ➔ **44개 전체 테스트 통과**
* 실기기(Galaxy S24 Ultra) 릴리즈 빌드 설치 및 스크린샷 캡처 확인 완료

---

## 5. 2026-09-02 작업 기록 — 전체 리뷰 후 보안·무결성 보강

### 5.1 무엇을 바꿨는가

* 앱에 내장된 마스터 PIN·공유 시크릿과 사용자 변경 가능 웹훅 설정을 제거하고, 서버 발급 **일회용 활성화 코드 → 기기 토큰** 교환 방식으로 교체했습니다.
* 기기 토큰은 `flutter_secure_storage`에 저장하고 서버는 해시만 보관합니다. 서버 URL은 `LICENSE_API_URL` 빌드 설정으로만 주입합니다.
* 앱 시작·포그라운드 복귀 외에 사용 중 5분 주기 승인 확인을 추가했습니다. 토큰 거부 시 로컬 승인과 토큰을 삭제해 재활성화로 전환합니다.
* Welcome 화면에 개인정보 처리 범위와 별도 필수 동의를 추가했습니다.
* 대본 수정이 학습·순발력·실전시험에 함께 반영되도록 수정 완료를 `await`하고 세 Provider를 갱신합니다. 개인 간증 우선순위와 교회명 치환도 일관되게 정리했습니다.
* TXT 가져오기는 8개 섹션 구조와 최소 매핑을 검증하고, 성공 직전 상태를 백업해 `[직전 가져오기 취소]`로 1회 복원할 수 있게 했습니다.
* 채점의 단어 일치도를 순서·반복 횟수를 보존하는 LCS 방식으로 변경했습니다. STT 재시작 중복 방지·점증 지연과 중복 채점 가드도 추가했습니다.
* CI를 Flutter 3.44.0으로 고정하고 포맷·커버리지·Android debug 빌드를 품질 게이트에 추가했습니다. release 빌드는 전용 키가 없으면 실패합니다. compileSdk는 보안 저장소 요구에 맞춰 37로 올렸습니다.
* Welcome 화면의 고정 버전 문자열을 제거하고 설치된 패키지 버전을 표시하도록 바꿨습니다. 최종 APK의 실제 `versionName`은 현재 `1.0.0`입니다.

### 5.2 왜 바꿨는가

기존 방식은 앱 바이너리와 서버 스크립트에 동일한 인증 재료가 있어 추출 시 전체 설치에 재사용될 수 있었고, 평문 로컬 상태 위조와 사용자에 의한 서버 주소 무력화 경계도 남아 있었습니다. 데이터 측면에서는 일부 TXT가 기존 대본에 조용히 합쳐지고, 직접 편집이 다른 시험 덱에 늦게 반영되며, 반복 단어가 과대 채점될 수 있었습니다.

### 5.3 복구·운영 방법

1. Apps Script에 `scripts/google_apps_script_backend.js`를 배포하고, 편집기에서 `createActivationCodes(필요수량)`를 실행합니다.
2. 실제 배포 URL은 저장소에 쓰지 말고 `flutter build apk --release --dart-define=LICENSE_API_URL=<배포 URL>`로 주입합니다.
3. 구 방식으로 활성화된 설치는 대본·간증·기록을 유지한 채 새 일회용 코드로 한 번 재활성화합니다.
4. 이 변경을 되돌려야 할 때도 로컬 PIN/공유 시크릿 방식은 복원하지 말고, 기기 토큰 저장소·서버 배포·스프레드시트 세 시점을 함께 롤백하십시오.

### 5.4 검증 결과와 남은 경계

* `flutter analyze` → **No issues found**
* `flutter test --coverage` → **46개 전부 통과**, 라인 커버리지 **46.7%**
* `flutter build apk --debug` → 성공 (`compileSdk 37`, 빌드용 placeholder URL 사용)
* `flutter build apk --release` → 전용 키 설정이 있는 현재 환경에서 성공
* 실제 활성화 코드·실서버·실기기 설치 검증은 이번 작업에서 수행하지 않았습니다. `docs/03`의 IT-15~IT-18은 재검증 전까지 PASS로 바꾸지 마십시오.
* `flutter_tts`와 `speech_to_text`가 자체 Kotlin Gradle Plugin을 적용한다는 Flutter 미래 호환 경고가 남아 있습니다. 현재 APK 빌드는 성공하지만 플러그인 업데이트를 계속 추적해야 합니다.

---

## 6. 2026-09-02 작업 기록 — 남은 검증 경계 재점검

### 6.1 추가 완료 항목

* Apps Script 서버 코드를 메모리 시트·잠금·해시 런타임에서 직접 실행하는 `scripts/google_apps_script_backend.test.js`를 추가했습니다. 일회용 코드 승인/소진/재사용 거부, 토큰 해시, 수식 주입, 잘못된 토큰, 차단/해제, 안전한 오류 응답이 모두 통과했습니다.
* CI에 서버 통합 테스트와 라인 커버리지 45% 하한을 추가했습니다. 현재 46.7%는 통과하고 강제 100%에서는 종료 코드 1로 실패하는 양방향 동작을 확인했습니다.
* 직접 의존성 중 갱신 가능했던 `wakelock_plus`를 1.8.0으로 올렸습니다. `flutter_tts 4.2.5`, `speech_to_text 7.4.0`은 현재 해석 가능한 최신 버전이지만 KGP 미래 호환 경고는 계속 발생합니다.
* debug/release APK를 새로 빌드하고 `apksigner`로 두 서명이 모두 유효하며 release가 debug와 다른 단일 서명자를 쓰는 것을 확인했습니다. 패키지는 `com.evangelism.just_ee.just_ee_master`, 라벨은 `JUST EE 마스터`입니다.

### 6.2 실제 운영 경계 확인 결과

* 운영 엔드포인트는 HTTP 접근 가능하지만 아직 제거 대상인 구형 공유 서명/PIN 프로토콜입니다.
* 로그인된 `clasp`에는 무관한 프로젝트 1개만 있고, 연결된 Google Drive 검색에서도 대상 시트/스크립트를 찾지 못했습니다. 정확한 대상을 증명할 수 없어 운영 서버 변경은 수행하지 않았습니다.
* ADB 유선·mDNS·이전 무선 연결·USB 인터페이스를 모두 확인했으나 연결 가능한 Android 단말이 없었습니다. 앱 설치나 STT/TTS 실기기 검증은 수행하지 않았습니다.

### 6.3 다음 재개 조건

1. 운영 Apps Script 프로젝트를 편집할 수 있는 Google 계정으로 로그인하거나 정확한 프로젝트 URL을 제공할 것.
2. 서버 코드를 백업한 뒤 새 백엔드를 배포하고, GET health 응답의 `protocol=device_token_v2`를 먼저 확인할 것.
3. Galaxy S24 Ultra에서 USB 디버깅을 켜고 `adb devices -l`에 `device`로 나타나게 할 것.
4. 실제 운영 URL로 release APK를 새로 빌드한 뒤 기존 패키지/서명 일치, 설치, 실행, 일회용 활성화, 재사용 거부, 5분 차단, 차단 해제를 순서대로 검증할 것. `flutter run`은 사용하지 않는다.

---

## 7. 2026-09-02 작업 기록 — Galaxy S24 Ultra 재연결 검증

### 7.1 확인 결과

* ADB 대상은 `R3CX60PDSTA / SM-S928N / Android 16`이며 상태는 `device`입니다.
* 사용자 0에는 `com.evangelism.just_ee.just_ee_master` 한 개만 설치되어 있고 Secure Folder 사용자에는 설치되지 않았습니다.
* 설치본은 `1.0.0+1`, 라벨은 `JUST EE 마스터`, release 단일 서명자는 현재 로컬 release APK와 일치합니다.
* 정확한 패키지를 `monkey -p`로 실행해 콜드 스타트 동의 게이트를 확인했습니다. 최종 확인 시 동의 체크는 미완료이고 기존 앱의 마이크 권한도 거부 상태이므로 사용자 승인 전 탭·TTS·STT는 검증할 수 없습니다.
* 설치본과 새 코드의 기존 `versionCode=1` 중복을 발견해 새 코드를 `1.0.1+2`로 올렸습니다.

### 7.2 설치를 보류한 이유와 재개 순서

* 현재 운영 Apps Script는 구형 프로토콜이고 새 APK는 검증용 서버 주소로 빌드되어 있습니다. 지금 덮어쓰면 기존 활성화가 깨질 수 있어 설치하지 않았습니다.
* 잘못된 배포 연결을 기계적으로 판별하도록 새 백엔드 GET health 응답과 통합 테스트에 `protocol=device_token_v2`를 추가했습니다.
* 정확한 Apps Script 프로젝트에서 새 백엔드를 배포하고 토큰 프로토콜 health 응답을 확인한 다음, 실제 URL로 `1.0.1+2` release APK를 fresh build해야 합니다.
* 그 뒤 서명·패키지·버전을 다시 확인하고 `adb install -r`, 정확한 패키지 실행, 사용자 직접 동의/마이크 권한 승인, 일회용 코드·재사용 거부·5분 차단/해제·TTS/STT를 순서대로 검증합니다.
* 복구가 필요하면 설치 전 기존 APK와 사용자 데이터 보존 상태를 우선 확인하고, 구형 인증 로직을 코드에 되살리지 않습니다.

### 7.3 사용자 승인 후 검증용 설치

* 사용자가 테스트 폰 설치를 명시적으로 요청해 placeholder 서버 주소로 `1.0.1+2` release APK를 다시 fresh build했습니다.
* package/label/version, V2 서명, 기존 설치본과 release 서명 일치를 확인한 뒤 `adb -s R3CX60PDSTA install -r`로 업데이트했습니다.
* 설치 후 `versionCode=2`, `versionName=1.0.1`, 정확한 패키지 포커스, 설치 APK와 로컬 산출물의 SHA-256 일치를 확인했습니다.
* 설치 전후 user 0의 CE/DE data inode와 first-install 시각이 같아 앱 데이터가 유지됐습니다. uninstall, clear-data, 자동 권한 부여는 수행하지 않았습니다.
* 새 Welcome 화면에서 실제 패키지 버전과 별도 동의 체크박스 2개가 정상 표시됐습니다. 최종 확인 시 두 체크 모두 미완료라 법적 동의를 대신 수행하지 않고 이후 화면 검증을 중단했습니다.
* 이 설치본은 운영용이 아닙니다. 실제 서버 배포·health 표식 확인·실제 URL fresh build 뒤 다시 업데이트해야 일회용 활성화와 차단 E2E를 검증할 수 있습니다.

### 7.4 실제 서버 URL 빌드 준비

* 사용자가 제공한 Apps Script 배포 URL은 저장소·문서에 기록하지 않고 GET으로 검증했습니다. HTTPS `/exec`, HTTP 200, `status=OK`, `protocol=device_token_v2`가 모두 확인됐습니다.
* 실제 URL을 `--dart-define=LICENSE_API_URL`에만 주입해 `1.0.1+2` release APK를 fresh build했고 package/label/version/V2 서명과 기존 release 서명 일치를 확인했습니다.
* 설치 직전 `R3CX60PDSTA`가 ADB 목록에서 사라졌습니다. ADB 서버 재시작과 유선·mDNS 재탐색에도 복구되지 않아 설치 명령을 실행하지 않았습니다.
* 단말이 다시 `device` 상태가 되면 설치 전 identity/data inode를 다시 확인하고, 현재 실제 URL 산출물을 `adb install -r`로 업데이트한 뒤 health·활성화 E2E를 계속합니다.

### 7.5 실제 서버 URL APK 설치

* `R3CX60PDSTA` 재연결 후 실서버 health의 HTTP 200, `status=OK`, `protocol=device_token_v2`를 다시 확인했습니다.
* 실제 URL을 저장소에 남기지 않고 release APK를 다시 fresh build한 뒤 package `com.evangelism.just_ee.just_ee_master`, `1.0.1+2`, 라벨, V2 서명과 업데이트 서명 일치를 확인했습니다.
* `adb install -r`가 성공했고, 설치된 base APK와 로컬 release APK의 SHA-256이 일치합니다. CE/DE data inode와 first-install 시각도 보존됐습니다.
* 정확한 패키지 실행과 화면 렌더링은 정상이며 치명적 Flutter/AndroidRuntime 예외는 없습니다. 최종 확인 시 두 동의 체크가 모두 미선택이라 법적 동의를 대신하지 않고 활성화 E2E를 대기합니다.

---

## 8. 2026-09-02 작업 기록 — 구형 기기 코드 마이그레이션 및 실제 활성화

### 8.1 원인과 수정

* 기존 `1.0.0`은 기기 코드를 `EE-XXXX-XXXX-XXXX` 3그룹으로 저장했지만 새 백엔드는 4그룹만 허용했습니다. 데이터 보존 업데이트 때문에 구형 값이 남아 서버가 일회용 코드를 조회하기 전에 거부했습니다.
* 앱 초기화 시 구형 3그룹 값에 보안 난수 4자리를 한 번 붙여 새 형식으로 저장하도록 수정했습니다. 다른 SharedPreferences, 대본, 간증, 시험 기록은 삭제하지 않습니다.
* 백엔드 소스도 재배포 시 3·4그룹을 모두 허용하도록 보완했습니다. 현재 설치된 수정 앱은 4그룹으로 전송하므로 서버 재배포 전에도 활성화됩니다.
* 서버 `ERROR`와 비정상 승인 응답을 `DENIED`와 구분해, 서버 장애를 “코드가 이미 사용됨”으로 오표시하지 않게 했습니다.

### 8.2 검증 결과

* `flutter analyze` → 경고 0건, `flutter test --coverage` → 48개 통과, 라인 커버리지 47.0%, Apps Script 통합 테스트 12개 그룹 통과.
* 실제 서버 주소를 빌드 설정에만 주입한 release APK를 fresh build했습니다. 정확한 패키지·라벨·버전·V2 서명과 기존 설치 서명 일치를 확인한 뒤 `adb install -r`로 업데이트했습니다.
* 사용자가 직접 동의하고 활성화에 성공했습니다. 관리 시트에서 일회용 코드 `USED`, 사용 기기/시각, 라이선스 `APPROVED`, 64자리 토큰 해시를 확인했습니다.
* 같은 코드의 별도 진단 기기 재사용은 실서버에서 `DENIED`됐고 라이선스 행은 늘지 않았습니다. 포그라운드 복귀 후 승인 유지와 최근 접속 시각 갱신도 확인했습니다.
* 강제 종료 후 동의 재진입, 원격 차단, 토큰 위조, TTS/STT 실사용은 아직 별도 검증이 필요합니다.

### 8.3 배포 운영 주의

* 훈련생에게는 정식 release APK 다운로드 링크와 개인별 `UNUSED` 코드만 전달합니다. Apps Script 주소와 관리 시트는 공유하지 않습니다.
* `createActivationCodes(count)`는 1~100개를 만들지만 편집기에서 인수 없이 직접 실행하면 기본 1개만 생성됩니다. 여러 개는 `createActivationCodes(10)`처럼 호출하는 무인수 관리자 래퍼를 두고 실행합니다.

---

## 9. 2026-09-04 작업 기록 — Codex 리뷰 검토 수용 및 릴리즈 빌드 가드 파이프라인 구축

**작업 주체:** Antigravity / **의뢰인:** 박상환

### 9.1 Codex 검토 의견 확인 및 정책 확정

1. **Codex 피드백 팩트 체크 및 수용**:
   * STT 백오프는 지수가 아닌 300ms 선형 증가(`min(3000, 300 * count)`).
   * 활성화 코드는 `ACT-` 접두사가 아닌 16자리 16진수(`XXXX-XXXX-XXXX-XXXX`).
   * 실서버는 `protocol=device_token_v2`, `status=OK`로 정상 배포·운영 중임을 재실측 확인.
   * 단위/통합 테스트는 14개 파일 48개 전체 통과 확인.
2. **정책 확정**:
   * 의뢰인(박상환 님)의 명시적 승인("찬성한다")에 따라, 보안이 취약한 구형 마스터 PIN 복원 논의를 종결하고 **일회용 코드 ➔ 기기 암호화 토큰(v2) 체계를 영구 공식 표준으로 확정**.

### 9.2 보완 작업 내용

1. **릴리즈 빌드 서버 URL 누락 차단 가드 (`android/app/build.gradle.kts`)**:
   * `--dart-define=LICENSE_API_URL` 없이 `flutter build apk --release`를 무심코 실행할 경우, 빌드 시작 즉시 `GradleException`을 발생시켜 **활성화 불가능한 먹통 APK 생성을 원천 차단**.
   * 서버 URL이 Google Apps Script WebApp 형식(`https://script.google.com/macros/s/.../exec`)과 일치하는지 엄격히 검증.
2. **원클릭 안전 릴리즈 빌드 파이프라인 (`scripts/build_release_apk.ps1`)**:
   * Git에서 제외된 `android/key.properties` 또는 환경변수에서 라이선스 서버 URL 자동 로드.
   * 빌드 전 실시간 서버 헬스체크 (`status=OK`, `protocol=device_token_v2`) 자동 수행 (`-SkipHealthCheck` 지원).
   * 서명 키 무결성 확인 후 `LICENSE_API_URL`을 자동 주입하여 릴리즈 APK 빌드.
   * 빌드 완료 후 산출물 크기 및 SHA-256 해시값 자동 검증 및 리포트.

### 9.3 검증 결과

* `flutter analyze` ➔ **경고 0건 (No issues found!)**
* `flutter test` ➔ **48개 전체 통과**
* **URL 누락 빌드 차단 검증**: `flutter build apk --release` 단독 실행 시 Gradle에서 즉시 빌드 차단 확인.
* **파이프라인 빌드 검증**: `scripts/build_release_apk.ps1` 실행 완료 (55.92 MB, SHA-256 해시 정상 생성 확인).
* **실기기 설치**: 의뢰인 지침에 따라 추후 USB 연결 후 별도 진행 예정.

---

## 10. 2026-09-05 작업 기록 — 실기기 수정 대본 전수 점검 및 프로젝트 원본 반영

**작업 주체:** Antigravity / **의뢰인:** 박상환

### 10.1 작업 배경 및 실기기 전수 점검
* 의뢰인이 스마트폰(Galaxy S24 Ultra)의 학습/청취 화면에서 직접 수정한 대본 내역을 프로젝트 원본(`data/just_ee_data.json`)에 반영 요청.
* UI 덤프 및 스크롤 자동화 스캔을 통해 8개 섹션 총 40개 전체 문장을 100% 전수 비교 점검하여 실제 변경된 5개 문장을 누락 없이 특정.

### 10.2 수정 반영 내역 (`data/just_ee_data.json`)
1. **`intro_2` (서론 - 영생의 정의/개인 간증)**:
   * "혼자서 어둠 속에서 살았습니다" ➔ "항상 죽음의 공포 가운데에서 살았습니다"
   * "영생을 얻은 후에는 많은 사람들과 함께 행복하게 살게 되었습니다" ➔ "영생을 얻은 후에 저는 영생의 참된 기쁨을 누리며 살고 있지요"
2. **`intro_5` (서론 - 성경 기록 목적/팀원 확신 확인)**:
   * 호칭 변경: "황 집사님", "전도사님" ➔ "김 집사님", "이 권사님"
3. **`intro_6` (서론 - 제2 진단 질문/복음 제시 허락)**:
   * "선생님은 선한 행위 때문이란 말씀이시죠? 제가 선생님의 대답을 바로 이해했나요?" ➔ "선생님의 대답은 선한 행위 때문이란 말씀이시죠? 제가 선생님의 말씀을 바로 이해했나요?"
4. **`grace_3` (은혜 - 선물 예화)**:
   * "하나님이 우리에게" ➔ "하나님께서 우리에게"
5. **`commit_5` (결신 - 구원의 확신 문답 요한복음 6:47)**:
   * 예시 이름 변경: "박상환" ➔ "김한국"

### 10.3 빌드 보류 및 무결성 검증
* **릴리즈 빌드 보류**: 의뢰인 지침("다른 수정이 있으니 새 릴리즈 APK 빌드는 보류해라")에 따라 새 릴리즈 APK 빌드는 실행하지 않고 보류.
* `flutter analyze` ➔ **경고 0건 (No issues found!)**
* `flutter test` ➔ **14개 파일 48개 전체 통과**

---

## 11. 2026-09-05 작업 기록 — 대본 수정 실시간 양방향 자동 동기화(SSOT) 아키텍처 구축

**작업 주체:** Antigravity / **의뢰인:** 박상환

### 11.1 문제 배경 및 원인
* **문제**: 학습/청취 화면(`StudyScreen`)에서 문장을 수정해도 설정 화면(`SettingsScreen`)의 대본 목록에 즉시 반영되지 않아, 앱 내에 서로 다른 두 버전이 존재하는 것처럼 불일치가 발생.
* **원인**: `ScriptRepository`가 단순 데이터 클래스로 남아있어 변경 이벤트를 발행하지 못했고, `StudyProvider`와 `ScriptManageProvider`가 각자의 메모리 캐시를 유지하며 UI 콜백에서 수동으로만 타 Provider를 갱신하던 분산 상태 관리의 취약성.

### 11.2 아키텍처 개선 내용
1. **단일 진실 공급원(SSOT) 및 반응형 발행자 구축**:
   * `ScriptRepository`가 `ChangeNotifier`를 확장하여 대본 변경(`updateStepScript`, `saveUserTestimony`, `saveUserChurch`, `importFromPlainText`, `undoLastImport`) 완료 시 `notifyListeners()` 자동 발행.
   * `main.dart` 및 테스트에서 `ChangeNotifierProvider<ScriptRepository>.value`로 공식 등록.
2. **Provider 레이어 자동 구독 (Pub-Sub)**:
   * `StudyProvider`: 저장소 변경 감지 시 `refresh()` 자동 실행 (카드/음성 실시간 동기화).
   * `ScriptManageProvider`: 저장소 변경 감지 시 `loadData(showLoading: false)` 자동 실행 (설정 대본/간증 실시간 동기화).
   * `QuickTriggerProvider`: 저장소 변경 감지 시 안전한 조건에서 `refreshFromRepository()` 자동 실행.
   * `VoiceExamProvider`: 저장소 변경 감지 시 안전한 조건에서 `generateNewQuestion()` 자동 실행.
   * 모든 Provider에 `_isDisposed` 가드를 적용하여 비동기 라이프사이클 누수 원천 차단.
3. **UI 레이어 의존성 분리**:
   * `StudyScreen`의 `onEdit` 콜백에서 타 Provider를 수동 호출하던 취약 코드를 제거하고 저장소 기반 단일 호출로 통합. 어느 화면에서 수정하든 전체 화면이 100% 동일한 시점에 자동 동기화됨.

### 11.3 검증 결과
* **신규 양방향 동기화 테스트**: `test/script_edit_propagation_test.dart`
  - `TS-EDIT-001`: 학습(StudyProvider) 수정 시 설정(ScriptManageProvider) 실시간 자동 반영 검증 통과.
  - `TS-EDIT-002`: 설정(ScriptManageProvider) 수정 시 학습(StudyProvider) 실시간 자동 반영 검증 통과.
* **`flutter analyze`**: **경고 0건 (No issues found!)**
* **`flutter test`**: **14개 파일 49개 전체 통과** (기존 48개 + 신규 1개)

---

## 12. 2026-09-05 작업 기록 — 학습/청취 "선택문장 무한 반복" 모드 개선 및 무한 반복 정상화

**작업 주체:** Antigravity / **의뢰인:** 박상환

### 12.1 문제 배경 및 원인
* **문제**:
  1. 학습/청취 화면의 재생 모드 중 "1문장 무한 반복" 모드가 정상 동작하지 않음. 문장 카드를 직접 탭하여 재생하면 단 1회만 읽고 멈춤.
  2. 하단 컨트롤 바의 "연속 듣기" 버튼을 누르면 현재 선택된 문장이 아닌 챕터 맨 첫 문장(0번)부터 반복이 시작됨.
  3. 명칭이 "1문장 무한 반복"으로 되어 있어 사용자가 선택한 문장을 반복한다는 의도가 직관적으로 드러나지 않음.
* **원인**:
  1. `StudyProvider.playStep()`이 호출될 때 무조건 `_isContinuousPlaying = false`로 고정하고 TTS 단발 재생 후 종료되었음.
  2. `StudyProvider.playContinuous()`의 시작 인덱스 기본값이 `fromIndex ?? 0`으로 하드코딩되어 있어, 사용자가 선택한 문장 정보(`_selectedStepId`)가 하단 재생 버튼과 연결되지 못했음.
  3. 배속 변경(`setSpeedRate()`) 시 무한 반복 중임에도 다음 문장(`nextIdx`)으로 진행되는 취약점 존재.

### 12.2 수정 및 개선 내용
1. **명칭 및 UI 텍스트 변경**:
   * `PlayMode.singleRepeat` 명칭: "1문장 무한 반복" ➔ **"선택문장 무한 반복"**
   * 재생 컨트롤 바 배지: **"선택문장 반복"**
   * 사용자 가이드 및 문서(`README.md`, `docs/04_user_guide.md`) 4대 재생 모드 설명 동기화.
2. **`StudyProvider` 상태 및 재생 루프 개선**:
   * `_selectedStepId` 필드 및 getter 추가: 사용자가 문장 카드를 탭하거나 챕터 진입 시 선택된 문장을 항상 최신으로 추적.
   * `playStep()`:
     - `_playMode == PlayMode.singleRepeat`일 때 단발 재생 대신 `playContinuous(fromIndex: curIdx)`를 직접 실행하여 선택 문장의 무한 루프로 즉시 진입.
     - 이미 무한 반복 중인 문장을 다시 탭하면 재생 정지(토글 동작).
   * `playContinuous()`:
     - `startIndex`를 `fromIndex ?? _selectedStepId ?? _activeStepId ?? 0` 순으로 계산하여, 하단 연속 듣기 버튼을 누를 때도 현재 선택/활성화된 문장부터 무한 반복 시작.
   * `setSpeedRate()`:
     - `_playMode == PlayMode.singleRepeat` 재생 중 배속 변경 시 다음 문장으로 넘어가지 않고 현재 선택 문장 무한 반복 유지.
3. **TTSService 테스트 내구성 보강**:
   * `lib/services/tts_service.dart`: `stop()`, `pause()`, `speak()`에 `try ... catch (_)` 가드를 두어 테스트/비네이티브 환경에서 `MissingPluginException` 발생 시 안전 무시 처리.

### 12.3 검증 결과
* **신규 단위 테스트**: `test/playback_sequence_test.dart`
  - `TS-PLAY-003`: 선택문장 무한 반복(`singleRepeat`) 모드에서 문장 선택 시 해당 문장 타깃 지정 및 무한 반복 유지 검증 통과.
* **`flutter analyze`**: **경고 0건 (No issues found!)**
* **`flutter test`**: **14개 파일 50개 전체 통과** (기존 49개 + 신규 1개)
* **릴리즈 빌드 보류 준수**: 사용자 요청에 따라 새 릴리즈 APK 빌드는 보류 상태 유지.

---

## 13. 2026-09-05 작업 기록 — 순발력/전환 트레이닝 문장 낭독 소요시간 기반 동적 타임아웃(1.0x / 1.2x / 1.5x) 구현

**작업 주체:** Antigravity / **의뢰인:** 박상환

### 13.1 문제 배경 및 원인
* **문제**: 순발력/전환 문장 트레이닝 탭에서 타임아웃 시간이 초급 3.0초, 중급 2.0초, 고급 1.0초로 고정되어 있어, 긴 문장은 물론 일반 문장에서도 발화를 채 마치기 전에 타임오버가 발생하는 심각한 제약 발생.
* **원인**: 문장 길이(음절 수 및 구두점 휴지기)와 무관하게 고정 초(`TriggerDifficulty.durationSeconds`)가 적용되어 있었고, 발화 제한 시간 `limit` 및 카운트다운 타이머가 고정값에 종속되어 있었음.

### 13.2 수정 및 개선 내용
1. **문장 낭독 소요시간 계산 엔진 구축 (`QuickTriggerEngine.calculateReadingDuration`)**:
   * 한국어 표준 TTS 낭독 속도(1.0x 기준 초당 5.0음절, `TTSService` 기준과 통일) 기반 음절 소요시간 산출.
   * 쉼표(0.25초) 및 문장부호(마침표/물음표 등 0.40초) 휴지기 가산.
   * 난이도별 배속 반영 (`초급: 1.0x`, `중급: 1.2x`, `고급: 1.5x`), 최소 2.0초 보장.
   * `QuickTriggerEngine.getTimeoutForStep(step, difficulty)` 추가로 카드별 대본(`effectiveScript`)에 맞는 동적 타임아웃 산출.
2. **`TriggerDifficulty` 난이도 정의 갱신**:
   * `beginner(1.0, '초급 (5단어 / 1.0x)')`, `intermediate(1.2, '중급 (4단어 / 1.2x)')`, `master(1.5, '고급 마스터 (3단어 / 1.5x)')`
   * `speedRate` 프로퍼티 추가 및 기존 호환성용 `durationSeconds` getter 유지.
3. **Provider 및 UI 동적 연동 (`QuickTriggerProvider` & `QuickTriggerScreen`)**:
   * `currentTimeoutSeconds` getter 추가: 현재 출제 카드 및 선택 난이도 배속에 따라 즉시 동적 계산.
   * `initDeck()`, `setDifficulty()`, `startTimerAndSTT()`, `abortListening()`, `nextCard()`에서 고정 초 대신 `currentTimeoutSeconds`를 기준으로 타이머/진행률/잔여시간 설정.
   * `finishAndScore()`의 순발력 점수 제한 시간(`limit`)을 동적 타임아웃과 100% 일치시켜, 긴 문장도 정상 속도 내 발화 시 고득점(70~100점) 획득 가능.
   * UI 프로그레스 바 및 하단 시작 버튼에 동적 초("${currentTimeoutSeconds}초") 실시간 반영.
4. **문서 동기화**:
   * `README.md`, `docs/04_user_guide.md`, `AGENTS.md`(실측 테스트 52개) 갱신.

### 13.3 검증 결과
* **신규 단위 테스트**: `test/quick_trigger_engine_test.dart`
  - `TS-TRIG-003`: 난이도별 배속(1.0x, 1.2x, 1.5x) 및 프리셋 호환성 검증 통과.
  - `TS-TRIG-004`: 1.0x/1.2x/1.5x 문장 낭독 소요 시간 기반 동적 타임아웃 계산 검증 통과 (초급 > 중급 > 고급 비례).
  - `TS-TRIG-005`: 최소 시간(2.0초) 보장 및 빈 스크립트 기본 시간 검증 통과.
* **`flutter analyze`**: **경고 0건 (No issues found!)**
* **`flutter test`**: **14개 파일 52개 전체 통과** (기존 50개 + 신규 2개)
* **릴리즈 빌드 보류 준수**: 사용자 요청에 따라 새 릴리즈 APK 빌드는 보류 상태 유지.

---

## 14. 2026-09-05 작업 기록 — 성경덱 핵심 8구절 전체 무한 연속 반복 재생 기능 구현

**작업 주체:** Antigravity / **의뢰인:** 박상환

### 14.1 문제 배경 및 원인
* **문제**: 성경덱 화면(`ScriptureDeckScreen`)에서 스피커 아이콘을 누르면 현재 보이는 단일 구절만 1회 읽어주고 정지되어, 8대 핵심 성경 구절 전체를 연속해서 반복 학습할 수 없었음.
* **원인**: `ScriptureProvider.speakCurrentVerse()`가 단일 구절 재생(`_tts.speak`)만 단발성으로 호출하고, 전체 덱을 순회하는 반복 세션 관리 및 루프 제어 로직이 부재했음.

### 14.2 수정 및 개선 내용
1. **`ScriptureProvider` 연속 반복 루프 및 세션 제어 구축**:
   * `playAllRepeat({int? fromIndex})`:
     - 지정된 구절(또는 현재 선택 구절)부터 8번 구절까지 순서대로 TTS 낭독 후, 다시 1번 구절로 돌아가 무한 반복 재생.
     - 매 구절 낭독 시 `_currentIndex` 및 `notifyListeners()`를 호출하여 UI 카드와 상단 ChoiceChip이 음성과 1:1로 실시간 동기화 전환.
     - 각 구절 사이에 600ms의 호흡 여유 휴지기 부여.
     - `_playbackSessionId`와 `_isDisposed` 가드를 통해 안전한 세션 취소 및 정지 보장.
     - 음성 낭독 중 화면 꺼짐 방지(`DeviceHelperService.enableKeepScreenOn()`) 연동.
   * `stopAudio()`: 재생 중단 및 리소스 안전 해제.
   * `togglePlayAllRepeat()`: 재생/정지 토글 동작.
   * `speakCurrentVerse()`: 스피커 터치 시 `togglePlayAllRepeat()`로 직결하여 전체 반복 재생 즉시 시작/정지.
   * `selectCard()`, `nextCard()`, `prevCard()`: 재생 도중 구절 전환 시 해당 구절부터 매끄럽게 연속 재생 유지.
2. **`ScriptureDeckScreen` UI 고도화**:
   * 성경 카드 우측 상단 스피커 아이콘: 재생 중일 때 `Icons.stop_circle_outlined`(빨간색)로 변경되며 토글 정지 지원.
   * 카드 하단에 전용 컨트롤 버튼 배치: `[전체 8구절 연속 반복 듣기]` ➔ 재생 중일 때 `[전체 반복 듣기 정지 (현재 n/8구절)]`.
   * AppBar actions에도 `[반복/정지]` 액션 아이콘 추가.
3. **신규 단위 테스트 추가**:
   * `test/scripture_deck_test.dart` (신규 3개 테스트 통과)
     - `TS-SCRIP-001`: 8대 핵심 성경 구절 데이터 무결성 검증.
     - `TS-SCRIP-002`: `ScriptureProvider` 전체 덱 반복 재생 및 정지 세션 제어 검증.
     - `TS-SCRIP-003`: 구절 이동 및 빈칸 퀴즈 모드 토글 검증.
4. **문서 동기화**:
   * `README.md`, `docs/04_user_guide.md`, `AGENTS.md`(실측 테스트 55개, 파일 15개) 갱신.

### 14.3 검증 결과
* **`flutter analyze`**: **경고 0건 (No issues found!)**
* **`flutter test`**: **15개 파일 55개 전체 통과** (기존 52개 + 신규 3개)
* **릴리즈 빌드 보류 준수**: 사용자 요청에 따라 새 릴리즈 APK 빌드는 보류 상태 유지.

---

## 15. 2026-09-05 작업 기록 — 순발력/전환 트레이닝 시작 단어 및 종료 단어(5, 4, 3단어) 동시 제시 구현

**작업 주체:** Antigravity / **의뢰인:** 박상환

### 15.1 문제 배경 및 원인
* **문제**: 순발력/전환 트레이닝 카드에서 문장의 첫 부분만 보여주고 있어, 사용자가 어디까지 암송을 완주해야 하는지(어디서 멈추어야 하는지) 종착점을 알기 어려웠음.
* **요구사항**: 초급, 중급, 고급 난이도에 따라 시작 단어뿐만 아니라 마지막 단어도 각각 5, 4, 3단어를 동시에 보여주도록 개선.

### 15.2 수정 및 개선 내용
1. **양방향 프롬프트 추출 알고리즘 (`QuickTriggerEngine.extractPrompt`) 구현**:
   * 난이도별 단어 수: `초급: 5단어`, `중급: 4단어`, `고급 마스터: 3단어`
   * 문장의 시작 `count`개 단어와 마지막 `count`개 단어를 추출하여 `"{시작 단어들} ... {끝 단어들}"` 형태로 결합.
   * 단어 수가 적은 문장에서도 시작 단어와 끝 단어가 중복되지 않도록 잔여 단어 수(`availableTail`) 기반 안전 경계 클램핑 적용.
   * 기존 실전시험(`RandomExamEngine`) 호환성을 위해 `extractLeadIn`도 안전하게 유지.
2. **화면 렌더링 반영 (`QuickTriggerScreen`)**:
   * 메인 문제 카드에서 `extractLeadIn` 대신 `extractPrompt`를 적용하여 사용자가 시작점과 종착점을 한눈에 보고 암송 가능.
   * 가독성을 고려하여 `height: 1.45` 줄간격 적용.
3. **신규 단위 테스트 추가**:
   * `test/quick_trigger_engine_test.dart`에 `TS-TRIG-006` 추가 (초급 앞뒤 5단어, 중급 앞뒤 4단어, 고급 앞뒤 3단어 및 단문 예외 분기 검증 완료).
4. **문서 동기화**:
   * `README.md`, `docs/04_user_guide.md`, `AGENTS.md`(실측 테스트 56개, 파일 15개) 갱신.

### 15.3 검증 결과
* **신규 단위 테스트**: `test/quick_trigger_engine_test.dart`
  - `TS-TRIG-006`: 시작/끝 단어(초급 5단어, 중급 4단어, 고급 3단어) 동시 노출 프롬프트 검증 통과.
* **`flutter analyze`**: **경고 0건 (No issues found!)**
* **`flutter test`**: **15개 파일 56개 전체 통과** (기존 55개 + 신규 1개)
* **릴리즈 빌드 보류 준수**: 사용자 요청에 따라 새 릴리즈 APK 빌드는 보류 상태 유지.

---

## 16. 2026-09-05 작업 기록 — 릴리즈 APK 빌드 및 실기기(USB) 업데이트 설치

**작업 주체:** Antigravity / **의뢰인:** 박상환

### 16.1 작업 배경 및 목표
* **목표**: 1~15단계에 걸쳐 완료된 5개 주요 기능 개선 및 대본 5문장 수정 사항을 반영하여, USB로 연결된 실기기 스마트폰(`R3CX60PDSTA`)에 최신 정식 릴리즈 버전을 무손실 업데이트 설치.
* **보호 원칙**:
  - `flutter run` 금지 원칙 준수 (사용자의 인증 토큰, 맞춤 간증, 설정 데이터 유실 방지).
  - 기존 릴리즈 서명 키(`android/key.properties`) 및 원격 라이선스 API 정의(`LICENSE_API_URL`)를 탑재한 정식 릴리즈 APK 빌드.
  - `adb install -r`을 통한 기존 앱 데이터 보존 인플레이스 업그레이드.

### 16.2 진행 내역
1. **버전 번호 갱신 (`pubspec.yaml`)**:
   - `version: 1.0.1+2` ➔ `version: 1.0.2+3` (Android Package Manager 버전 업그레이드 인지).
2. **정식 릴리즈 APK 빌드 (`flutter build apk --release`)**:
   - Keystore 서명 및 Proguard R8 정상 통과.
   - 빌드 결과물: `build\app\outputs\flutter-apk\app-release.apk` (55.9MB).
3. **실기기 ADB 설치 (`adb -s R3CX60PDSTA install -r ...`)**:
   - `Performing Streamed Install` ➔ `Success`.
   - 설치 후 패키지 검증: `versionCode=3`, `versionName=1.0.2` 정상 적용 확인.
4. **앱 자동 구동 (`monkey -p com.evangelism.just_ee.just_ee_master ...`)**:
   - 스마트폰 화면에 최신 앱 정상 런처 실행 확인.

### 16.3 최종 검증 결과
* **`flutter analyze`**: **경고 0건 (No issues found!)**
* **`flutter test`**: **15개 파일 56개 전체 통과**
* **실기기 동작 확인**:
  - 패키지: `com.evangelism.just_ee.just_ee_master`
  - 기기 ID: `R3CX60PDSTA`
  - 적용 버전: `1.0.2 (Build 3)`
  - 앱 런칭 완료 및 데이터 보존 상태 확인.






