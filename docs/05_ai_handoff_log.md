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
| 검증 명령 | `flutter analyze` (경고 0건 유지) / `flutter test` (**30개** 통과) |
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

## 2. 이 저장소에서 작업하는 AI를 위한 규칙

1. **문서와 코드가 다르면 코드가 정답입니다.** 단, 사용자 노출 문구(문장 수 등)가 데이터와 어긋나면 그것은 코드 버그이니 데이터 기준으로 고치십시오.
2. **되살리면 안 되는 기능**: 즉석 양육 마스터 화면 계열(§1.2), 대본 일괄 복원 버튼. 둘 다 의도적으로 제거되었습니다.
3. **문서에 실제 마스터 인증키·웹훅 비밀 값을 쓰지 마십시오.** (§1.5)
4. **숫자를 문서에 쓸 때는 반드시 실측하십시오.** 문장 수는 `data/just_ee_data.json`, 구절 수는 `scripture_deck_engine.dart`, 테스트 수는 `flutter test` 실행 결과가 근거입니다.
5. **작업을 마치면 `flutter analyze`와 `flutter test`를 모두 돌리고, 그 출력을 근거로만 "통과"를 주장하십시오.**
6. **코드를 바꿨으면 관련 문서(README, `docs/01`~`docs/04`)를 같은 작업 안에서 갱신하고, 이 문서 §1 형식으로 새 절을 추가하십시오.**
7. 원문(복음 제시 전문) 텍스트는 사단법인 한국전도폭발본부 저작물입니다. 임의로 문구를 창작·윤색하지 마십시오.
