# 전도폭발 JUST EE 단위 및 모듈 테스트 명세서 (Module Test Specifications)

**문서 버전:** v2.6
**작성일:** 2026-09-05
**테스트 프레임워크:** Flutter Test (`flutter test`)  
**테스트 스위트 구성:** 총 15개 파일, 61개 단위/위젯 테스트 (100% 통과)
**최종 실행 결과:** 2026-09-05 앱 `1.0.3+4` / `flutter test` → `+61: All tests passed!` / `flutter analyze` → `No issues found!` / release APK 실기기 검증 완료

---

## 1. 모듈별 테스트 명세 요약

| 테스트 파일 | 테스트 ID | 검증 대상 모듈 | 테스트 시나리오 및 검증 내용 | 결과 |
| :--- | :--- | :--- | :--- | :---: |
| `license_service_test.dart` | TS-LIC-001 | `LicenseService` | 4그룹 기기 코드 발급 및 재초기화 시 영구 보관 검증 | PASS |
| | TS-LIC-007 | `LicenseService` | 구형 3그룹 기기 코드를 다른 사용자 데이터 삭제 없이 4그룹으로 1회 확장 | PASS |
| | TS-LIC-002 | `LicenseService` | 서버 `APPROVED`와 기기 토큰이 모두 있어야 활성화되는지 검증 | PASS |
| | TS-LIC-003 | `LicenseService` | 서버가 거부한 일회용 코드는 로컬 활성화되지 않는지 검증 | PASS |
| | TS-LIC-008 | `LicenseService` | 서버 `ERROR`를 코드 무효·재사용 메시지로 오표시하지 않는지 검증 | PASS |
| | TS-LIC-004 | `LicenseService` | 서버에서 차단 해제 시 기존 토큰으로 정상 활성화 복구 검증 | PASS |
| | TS-LIC-005 | `LicenseActivationScreen` | 일회용 코드 입력 UI 렌더링 검증 | PASS |
| | TS-LIC-006 | `BlockedScreen` | 원격 차단 사유 렌더링 검증 | PASS |
| `korean_text_normalizer_test.dart` | TS-NORM-001 | `KoreanTextNormalizer` | 추임새 및 간투사("어...", "음...") 자동 필터링 | PASS |
| | TS-NORM-002 | `KoreanTextNormalizer` | 성경 장/절 및 한글 수사 ➔ 아라비아 숫자 통일 변환 | PASS |
| | TS-NORM-003 | `KoreanTextNormalizer` | 특수문자 및 다중 공백 제거 정제 검증 | PASS |
| `quick_trigger_engine_test.dart` | TS-TRIG-001 | `QuickTriggerEngine` | 문장 선두부(Lead-in) 난이도별 3/4/5단어 추출 | PASS |
| | TS-TRIG-002 | `QuickTriggerEngine` | 덱 생성 시 셔플 무결성 및 전환문장 필터링 | PASS |
| | TS-TRIG-003 | `QuickTriggerEngine` | 난이도별 배속(1.0x, 1.2x, 1.5x) 및 프리셋 호환성 검증 | PASS |
| | TS-TRIG-004 | `QuickTriggerEngine` | 1.0x/1.2x/1.5x 문장 낭독 소요 시간 기반 동적 타임아웃 계산 검증 | PASS |
| | TS-TRIG-005 | `QuickTriggerEngine` | 최소 시간 2.0초 보장 및 빈 스크립트 기본 시간 검증 | PASS |
| | TS-TRIG-006 | `QuickTriggerEngine` | 시작/끝 단어(초급 5단어, 중급 4단어, 고급 3단어) 동시 노출 프롬프트 검증 | PASS |
| `random_exam_engine_test.dart` | TS-RAND-001 | `RandomExamEngine` | 전환 ➔ 다음 단락 연계 암송 출제 검증 | PASS |
| | TS-RAND-002 | `RandomExamEngine` | 예화 집중 완주 출제 검증 | PASS |
| | TS-RAND-003 | `RandomExamEngine` | 실전시험에서 순수 성경 구절 제외 및 34문장 구성 검증 | PASS |
| | TS-RAND-004 | `RandomExamEngine` | 즉석 양육 항목별 출제 검증 | PASS |
| | TS-RAND-005 | `RandomExamEngine` | 실전시험 4대 영역별 세부 성적표 산출 검증 | PASS |
| | TS-RAND-006 | `RandomExamEngine` | 성경 구절 암송 모드 예외적 성경 구절 출제 검증 | PASS |
| `scoring_engine_test.dart` | TS-SCORE-001 | `ScoringEngine` | 100% 일치 발화 채점 (Myers Diff & 100점 산출) | PASS |
| | TS-SCORE-002 | `ScoringEngine` | 핵심 키워드 누락 시 가중치 감점 및 Missing 마킹 | PASS |
| | TS-SCORE-003 | `ScoringEngine` | 빈 문자열 발화 시 0점 및 전체 Missing 처리 | PASS |
| `script_edit_propagation_test.dart` | TS-EDIT-001 | `ScriptManageProvider` | 문장 개별 수정 시 StudyProvider 및 채점 엔진 즉시 반영 | PASS |
| | TS-EDIT-002 | `ScriptManageProvider` | 설정(ScriptManageProvider)에서 수정 시 학습(StudyProvider)에 수동 호출 없이 실시간 자동 동기화 검증 | PASS |
| `script_import_test.dart` | TS-IMPO-001 | `ScriptRepository` | 외부 TXT 전문 파싱 및 8대 섹션 자동 분류 검증 | PASS |
| | TS-IMPO-002 | `ScriptRepository` | 구조 없는 텍스트 거부 및 기존 대본 보존 검증 | PASS |
| | TS-IMPO-003 | `ScriptRepository` | 직전 가져오기 백업 복원 및 1회성 되돌리기 검증 | PASS |
| `transition_engine_test.dart` | TS-TRANS-001 | `TransitionSentenceEngine` | 교재 데이터 기반 6대 전환문장 생성 및 대지 순서 검증 | PASS |
| | TS-TRANS-002 | `TransitionSentenceEngine` | 전환문장이 실제 교재 대본 안에 포함되어 있는지 검증 (목록·대본 불일치 방지) | PASS |
| `tts_syllable_test.dart` | TS-TTS-001 | `TTSService` | 발화 시작 초기(0.5초 이내) 문장 전체 반환 (건너뜀 방지) | PASS |
| | TS-TTS-002 | `TTSService` | 문장 중간(1.8초, 1.0배속) 안전 중첩 어절 포함 | PASS |
| | TS-TTS-003 | `TTSService` | 긴 문장에서 3.0초 경과 시 단어 건너뜀 방지 어절 유지 | PASS |
| | TS-TTS-004 | `TTSService` | 2.0배속 고속 발화 시에도 안전하게 이전 어절 포함 | PASS |
| `user_custom_script_import_test.dart` | TS-CUST-001 | `ScriptRepository` | 사용자 전도폭발 전문 텍스트 파싱 및 8대 대지 매핑 | PASS |
| `security_regression_test.dart` | TS-SEC-001 | `LicenseService` | 코드 형태나 접두사만으로는 활성화되지 않고 매번 서버 승인이 필요한지 검증 | PASS |
| | TS-SEC-002 | `LicenseService` | 승인 상태 확인 요청에 보안 저장소의 기기 토큰을 쓰는지 검증 | PASS |
| | TS-SEC-003 | `LicenseService` | 토큰 거부 시 로컬 승인과 토큰을 삭제하는지 검증 | PASS |
| | TS-SEC-004 | `LicenseService` | 허용된 Apps Script HTTPS 주소 외에는 통신하지 않는지 검증 | PASS |
| `scoring_rules_test.dart` | TS-SCORE-004 | `ScoringEngine` | 조사·어미 차이는 정답, 다른 단어는 오답으로 판정하는 어간 규칙 검증 | PASS |
| | TS-SCORE-005 | `ScoringEngine` | 정확한 발화 100점 / 전혀 다른 발화 30점 미만 산출 검증 | PASS |
| | TS-NORM-004 | `KoreanTextNormalizer` | 지시어·감탄사(그/이/아) 보존 및 실제 추임새만 제거 검증 | PASS |
| | TS-NORM-005 | `KoreanTextNormalizer` | 장/절 수사만 숫자 변환하고 "사장님"·"일절"은 보존하는지 검증 | PASS |
| | TS-SCORE-006 | `ScoringEngine` | 전체 완주 분량(800자 초과) 지문의 아이솔레이트 비동기 채점 동작 검증 | PASS |
| | TS-SCORE-007 | `ScoringEngine` | 반복 단어를 실제 발화 횟수만큼만 순서대로 일치 처리하는지 검증 | PASS |
| | TS-SCORE-008 | `ScoringEngine` | 띄어쓰기 차이에 대한 점수 복원력 및 키워드 인식 검증 | PASS |
| | TS-SCORE-009 | `ScoringEngine` | 중간 문장 건너뛰기 시 LCS 역추적으로 뒤 문장 정확 매칭 검증 | PASS |
| | TS-SCORE-010 | `KoreanTextNormalizer` | 한국어 수사 및 서수사 표준 정규화 검증 | PASS |
| `playback_sequence_test.dart` | TS-PLAY-001 | `StudyProvider` | 전체 완주 재생 시 시작 챕터만 중간부터, 이후 챕터는 첫 문장부터 재생 검증 | PASS |
| | TS-PLAY-002 | `ScriptRepository` | 교재 전문 8개 챕터 40문장 구성 검증 | PASS |
| | TS-PLAY-003 | `StudyProvider` | 선택문장 무한 반복(singleRepeat) 모드에서 문장 선택 시 해당 문장 타깃 지정 및 유지 검증 | PASS |
| | TS-HIST-001 | `ScriptRepository` | 시험 이력 최대 50건 상한 및 최신순 정렬 검증 | PASS |
| `scripture_deck_test.dart` | TS-SCRIP-001 | `ScriptureDeckEngine` | 8대 성경 구절 로드 및 카테고리/의미/빈칸 데이터 무결성 검증 | PASS |
| | TS-SCRIP-002 | `ScriptureProvider` | ScriptureProvider 전체 성경덱 반복 재생(playAllRepeat) 토글 및 정지 검증 | PASS |
| | TS-SCRIP-003 | `ScriptureProvider` | 구절 순환(nextCard/prevCard/selectCard) 및 빈칸 퀴즈 모드 토글 검증 | PASS |
| `widget_test.dart` | TS-WIDG-001 | `MainNavigationScreen` | BottomNavigationBar 5개 탭 렌더링 확인 | PASS |
| | TS-WIDG-002 | `WelcomeTermsScreen` | 저작권 및 개인정보 별도 필수 동의 게이트 검증 | PASS |
| | TS-STUDY-007 | `AudioControlBar` | 1.2x 배속 추가 및 2.5x 삭제 렌더링/이벤트 검증 | PASS |

---

## 2. 폐기된 테스트 (2026-08-29)

| 폐기 테스트 ID | 사유 |
| :--- | :--- |
| TS-FOLL-001 / 002 / 004 (`follow_up_engine_test.dart`) | 검증 대상인 `FollowUpEngine`·`FollowUpProvider`·`FollowUpMasterScreen`이 어느 화면에서도 참조되지 않는 미연결 코드로 확인되어 계열 전체 삭제. |
| TS-EDIT-001의 "기본값 복원" 단계 | 설정 화면의 대본 복원 UI가 커밋 `93fd9eb`에서 영구 제거됨에 따라, 해당 검증 단계와 `resetAll()`/`resetToDefault()` 잔재 코드를 함께 삭제. 문장 수정 전파 및 채점 반영 검증은 그대로 유지. |

삭제 배경과 복구 방법은 [05_ai_handoff_log.md](05_ai_handoff_log.md)에 기록되어 있습니다.

---

## 3. 테스트 실행 명령어
```bash
flutter test --coverage  # 61개 단위/위젯 테스트
flutter analyze   # 정적 분석 (경고 0건 유지)
node scripts/google_apps_script_backend.test.js  # 서버 통합 테스트
dart run scripts/check_coverage.dart coverage/lcov.info 45  # 커버리지 하한
```

### Apps Script 백엔드 통합 검증

`google_apps_script_backend.test.js`는 메모리 시트와 Apps Script 런타임 API를 사용해 다음 경계를 실제 서버 코드로 검증합니다.

* health 응답의 `protocol=device_token_v2` 표식
* 유효하지 않은 기기는 코드를 소진하지 않음
* 일회용 코드의 대소문자·구분자 정규화, 최초 승인 및 재사용 거부
* 토큰 원문 대신 SHA-256 해시 저장
* 정상 토큰 승인, 잘못된 토큰 거부, 원격 차단과 해제
* 스프레드시트 수식 주입 차단 및 예외 원문 비노출

CI는 라인 커버리지 **45% 하한**도 강제합니다. 현재 실측은 **47.0%**이며, 100% 하한을 넣은 음성 테스트에서 종료 코드 1로 실제 차단되는 것도 확인했습니다.
