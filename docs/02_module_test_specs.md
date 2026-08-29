# 전도폭발 JUST EE 단위 및 모듈 테스트 명세서 (Module Test Specifications)

**문서 버전:** v2.1  
**작성일:** 2026-08-29  
**테스트 프레임워크:** Flutter Test (`flutter test`)  
**테스트 스위트 구성:** 총 11개 파일, 33개 단위/위젯 테스트 (100% 통과)

---

## 1. 모듈별 테스트 명세 요약

| 테스트 파일 | 테스트 ID | 검증 대상 모듈 | 테스트 시나리오 및 검증 내용 | 결과 |
| :--- | :--- | :--- | :--- | :---: |
| `license_service_test.dart` | TS-LIC-001 | `LicenseService` | 기기 고유 UUID 발급 및 SharedPreferences 영구 보관 검증 | PASS |
| | TS-LIC-002 | `LicenseService` | 올바른 마스터 PIN 입력 시 활성화 및 상태 변경 검증 (방안 2) | PASS |
| | TS-LIC-003 | `LicenseService` | 잘못된 PIN 입력 시 활성화 거부 검증 | PASS |
| | TS-LIC-004 | `LicenseService` | 원격 킬스위치 차단 시 Blocked 상태 전환 검증 (방안 1) | PASS |
| | TS-LIC-005 | `LicenseActivationScreen` | UI 렌더링, 기기 코드 복사 및 PIN 입력 필드 검증 | PASS |
| | TS-LIC-006 | `BlockedScreen` | 비인가 단말기 접근 차단 화면 및 사유 렌더링 검증 | PASS |
| `follow_up_engine_test.dart` | TS-FOLL-001 | `FollowUpEngine` | 요한복음 6:47 확신 4문답 구어체 의도 매칭 검증 (Q2 영생) | PASS |
| | TS-FOLL-002 | `FollowUpEngine` | 5손가락 영적 성장 수단 매핑 무결성 검증 | PASS |
| | TS-FOLL-004 | `FollowUpEngine` | 확신 질문 Q3(천국) 및 Q4(십자가/약속) 의도 매칭 | PASS |
| `korean_text_normalizer_test.dart` | TS-NORM-001 | `KoreanTextNormalizer` | 추임새 및 간투사("어...", "음...") 자동 필터링 | PASS |
| | TS-NORM-002 | `KoreanTextNormalizer` | 성경 장/절 및 한글 수사 ➔ 아라비아 숫자 통일 변환 | PASS |
| | TS-NORM-003 | `KoreanTextNormalizer` | 특수문자 및 다중 공백 제거 정제 검증 | PASS |
| `quick_trigger_engine_test.dart` | TS-TRIG-001 | `QuickTriggerEngine` | 문장 선두부(Lead-in) 난이도별 3/4/5단어 추출 | PASS |
| | TS-TRIG-002 | `QuickTriggerEngine` | 덱 생성 시 셔플 무결성 및 전환문장 필터링 | PASS |
| | TS-TRIG-003 | `QuickTriggerEngine` | 난이도별 프리셋 시간(1.0s, 2.0s, 3.0s) 검증 | PASS |
| `random_exam_engine_test.dart` | TS-RAND-001 | `RandomExamEngine` | 전환 ➔ 다음 단락 연계 암송 출제 검증 | PASS |
| | TS-RAND-002 | `RandomExamEngine` | 예화 집중 완주 출제 검증 | PASS |
| | TS-RAND-003 | `RandomExamEngine` | 성경 구절 암송 출제 검증 | PASS |
| | TS-RAND-004 | `RandomExamEngine` | 즉석 양육 항목별 출제 검증 | PASS |
| | TS-RAND-005 | `RandomExamEngine` | 모의 구두시험 5대 영역별 세부 성적표 산출 검증 | PASS |
| `scoring_engine_test.dart` | TS-SCORE-001 | `ScoringEngine` | 100% 일치 발화 채점 (Myers Diff & 100점 산출) | PASS |
| | TS-SCORE-002 | `ScoringEngine` | 핵심 키워드 누락 시 가중치 감점 및 Missing 마킹 | PASS |
| | TS-SCORE-003 | `ScoringEngine` | 빈 문자열 발화 시 0점 및 전체 Missing 처리 | PASS |
| `script_edit_propagation_test.dart` | TS-EDIT-001 | `ScriptManageProvider` | 문장 개별 수정 시 StudyProvider 및 채점 엔진 즉시 반영 | PASS |
| `script_import_test.dart` | TS-IMPO-001 | `ScriptRepository` | 외부 TXT 전문 파싱 및 8대 섹션 자동 분류 검증 | PASS |
| `transition_engine_test.dart` | TS-TRANS-001 | `TransitionEngine` | 6대 대지 전환문장 무결성 및 순서 검증 | PASS |
| `tts_syllable_test.dart` | TS-TTS-001 | `TTSService` | 발화 시작 초기(0.5초 이내) 문장 전체 반환 (건너뜀 방지) | PASS |
| | TS-TTS-002 | `TTSService` | 문장 중간(1.8초, 1.0배속) 안전 중첩 어절 포함 | PASS |
| | TS-TTS-003 | `TTSService` | 긴 문장에서 3.0초 경과 시 단어 건너뜀 방지 어절 유지 | PASS |
| | TS-TTS-004 | `TTSService` | 2.0배속 고속 발화 시에도 안전하게 이전 어절 포함 | PASS |
| `user_custom_script_import_test.dart` | TS-CUST-001 | `ScriptRepository` | 사용자 전도폭발 전문 텍스트 파싱 및 8대 대지 매핑 | PASS |
| `widget_test.dart` | TS-WIDG-001 | `MainNavigationScreen` | BottomNavigationBar 5개 탭 렌더링 확인 | PASS |
| | TS-WIDG-002 | `WelcomeTermsScreen` | 저작권 고지, 개발자 정보 및 동의 체크박스 게이트 검증 | PASS |

---

## 2. 테스트 실행 명령어

```bash
flutter test
```
