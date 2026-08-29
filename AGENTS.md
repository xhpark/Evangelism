# AGENTS.md — AI 에이전트 작업 규칙

이 저장소는 여러 AI 코딩 에이전트(Antigravity, Claude Code 등)가 번갈아 작업합니다.
**작업을 시작하기 전에 반드시 [docs/05_ai_handoff_log.md](docs/05_ai_handoff_log.md)를 먼저 읽으십시오.**
거기에 최근 작업 내역, 의도적으로 제거된 기능(되살리면 안 되는 것), 보안 관련 금지 사항이 기록되어 있습니다.

## 프로젝트 개요

전도폭발(EE) 복음 제시 전문 암송 훈련 Flutter 앱 (Android 대상, Provider/MVVM).

| 확인할 것 | 근거 파일 |
| :--- | :--- |
| 대본 8섹션 / 총 40문장 | `data/just_ee_data.json` |
| 성경 암송 8구절 | `lib/services/scripture_deck_engine.dart` |
| 전환문장 6개 | `data/just_ee_data.json`의 `transition_text` |
| 등록된 Provider 6종 | `lib/main.dart` |
| 테스트 42개 (14개 파일) | `test/` |

## 필수 규칙

1. **문서와 코드가 다르면 코드가 정답.** 코드를 바꿨으면 `README.md`와 `docs/01`~`docs/04`를 같은 작업 안에서 갱신한다.
2. **작업 기록을 남긴다.** 끝난 뒤 `docs/05_ai_handoff_log.md`에 §1과 같은 형식으로 새 절을 추가한다 (무엇을·왜·복구 방법).
3. **되살리면 안 되는 것**: 즉석 양육 마스터 화면 계열(`FollowUpMasterScreen`/`FollowUpProvider`/`FollowUpEngine`), 설정 화면의 "교재 기본 대본 전체 복원" 버튼, 그리고 `LicenseService`의 `"JUST"` 접두 인증키 우회 분기. 모두 의도적으로 제거됨 (`TS-SEC-001`이 우회 복원을 차단).
4. **비밀 값 금지**: 마스터 인증키(`LicenseService._masterPins`), 공유 시크릿(`_sharedSecret`), 웹훅 URL의 실제 값을 문서·커밋 메시지·이슈에 기재하지 않는다. 시크릿을 바꾸면 앱과 Apps Script를 함께 바꿔 재배포해야 한다.
5. **숫자는 실측한다**: 문장 수·구절 수·테스트 수를 문서에 쓸 때는 위 표의 근거 파일이나 명령 출력으로 확인한다.
6. **완료 주장 전 검증**: `flutter analyze`(경고 0건)와 `flutter test`(전부 통과)를 실행하고 그 출력을 근거로만 완료를 보고한다.
7. **원문 저작권**: 복음 제시 전문 텍스트는 사단법인 한국전도폭발본부 저작물이므로 임의로 창작·윤색하지 않는다.

## 자주 쓰는 명령

```bash
flutter analyze            # 경고 0건 유지
flutter test               # 42개 통과
flutter build apk --debug  # Android 설정 변경 시 반드시 확인
```

## 주의가 필요한 구조

* `STTService`는 **싱글턴**이다. 탭마다 인스턴스를 만들면 상태 콜백이 선점되어 '인식 중'에서 멈춘다. 콜백은 `startListening()` 호출 시 주입한다.
* 긴 지문 채점은 `ScoringEngine.calculateScoreAsync()`(아이솔레이트)를 쓴다. 동기 `calculateScore()`를 UI에서 직접 부르면 수 초간 화면이 멈춘다.
* 안드로이드 `flutter_tts`는 배속 값을 2배로 곱해 넘긴다. 배속 관련 코드는 `TTSService._platformRate` 하나만 고친다.
* 문장 수·구절 수를 UI 문자열에 하드코딩하지 않는다. 데이터에서 센다.
