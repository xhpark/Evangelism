import 'package:flutter_test/flutter_test.dart';
import 'package:just_ee_master/models/step_item_model.dart';
import 'package:just_ee_master/services/quick_trigger_engine.dart';

void main() {
  group('QuickTriggerEngine Tests (TS-TRIG-001, TS-TRIG-003)', () {
    test('TS-TRIG-001: 문장 선두부(Lead-in text) 난이도별 3/4/5 단어 추출 검증', () {
      const sentence = "선생님 만약 가장 절친한 친구가 선생님을 위해 값비싼 시계를 선물로 주었다고 생각해 보십시오";

      final masterLeadIn = QuickTriggerEngine.extractLeadIn(
        sentence,
        difficulty: TriggerDifficulty.master,
      );
      final interLeadIn = QuickTriggerEngine.extractLeadIn(
        sentence,
        difficulty: TriggerDifficulty.intermediate,
      );
      final beginLeadIn = QuickTriggerEngine.extractLeadIn(
        sentence,
        difficulty: TriggerDifficulty.beginner,
      );

      // 고급: 3단어
      expect(masterLeadIn, equals("선생님 만약 가장..."));
      // 중급: 4단어
      expect(interLeadIn, equals("선생님 만약 가장 절친한..."));
      // 초급: 5단어
      expect(beginLeadIn, equals("선생님 만약 가장 절친한 친구가..."));
    });

    test('TS-TRIG-002: 덱 생성 시 셔플 무결성 및 전환문장 필터링', () {
      final sampleSteps = [
        StepItem(
          stepId: '1',
          name: '은혜 1',
          type: StepType.truth,
          summary: '요약 1',
          script: '문장 1',
          isTransition: false,
        ),
        StepItem(
          stepId: '2',
          name: '은혜 전환',
          type: StepType.transition,
          summary: '전환 요약',
          script: '전환 문장',
          isTransition: true,
        ),
      ];

      final transitionDeck = QuickTriggerEngine.generateDeck(
        sampleSteps,
        onlyTransitions: true,
      );
      expect(transitionDeck.length, equals(1));
      expect(transitionDeck.first.isTransition, isTrue);
    });

    test('TS-TRIG-003: 난이도별 배속(1.0x, 1.2x, 1.5x) 및 프리셋 호환성 검증', () {
      expect(TriggerDifficulty.beginner.speedRate, equals(1.0));
      expect(TriggerDifficulty.intermediate.speedRate, equals(1.2));
      expect(TriggerDifficulty.master.speedRate, equals(1.5));

      // 기존 durationSeconds getter 호환성
      expect(TriggerDifficulty.beginner.durationSeconds, equals(3.0));
      expect(TriggerDifficulty.intermediate.durationSeconds, equals(2.0));
      expect(TriggerDifficulty.master.durationSeconds, equals(1.0));
    });

    test('TS-TRIG-004: 1.0x/1.2x/1.5x 문장 낭독 소요 시간 기반 동적 타임아웃 계산 검증', () {
      const sentence = "선생님 만약 가장 절친한 친구가 선생님을 위해 값비싼 시계를 선물로 주었다고 생각해 보십시오.";

      final step = StepItem(
        stepId: 'test_step',
        name: '테스트 스텝',
        type: StepType.illustration,
        summary: '요약',
        script: sentence,
      );

      final beginnerTimeout = QuickTriggerEngine.getTimeoutForStep(
        step,
        TriggerDifficulty.beginner,
      );
      final interTimeout = QuickTriggerEngine.getTimeoutForStep(
        step,
        TriggerDifficulty.intermediate,
      );
      final masterTimeout = QuickTriggerEngine.getTimeoutForStep(
        step,
        TriggerDifficulty.master,
      );

      // 초급(1.0x): 39음절/5.0 + 0.4초(마침표) = 8.2초
      expect(beginnerTimeout, equals(8.2));
      // 중급(1.2x): 8.2 / 1.2 = 6.833... => 6.8초
      expect(interTimeout, equals(6.8));
      // 고급(1.5x): 8.2 / 1.5 = 5.466... => 5.5초
      expect(masterTimeout, equals(5.5));

      // 난이도별 타임아웃 대소 관계 검증 (초급 > 중급 > 고급)
      expect(beginnerTimeout > interTimeout, isTrue);
      expect(interTimeout > masterTimeout, isTrue);
    });

    test('TS-TRIG-005: 최소 시간 2.0초 보장 및 빈 스크립트 기본 시간 검증', () {
      final shortTimeout = QuickTriggerEngine.calculateReadingDuration(
        "죄",
        speedRate: 1.5,
      );
      expect(shortTimeout, equals(2.0));

      final emptyTimeout = QuickTriggerEngine.calculateReadingDuration(
        "",
        speedRate: 1.0,
      );
      expect(emptyTimeout, equals(3.0));
    });

    test('TS-TRIG-006: 시작/끝 단어(초급 5단어, 중급 4단어, 고급 3단어) 동시 노출 프롬프트 검증', () {
      const sentence = "선생님 만약 가장 절친한 친구가 선생님을 위해 값비싼 시계를 선물로 주었다고 생각해 보십시오";

      final masterPrompt = QuickTriggerEngine.extractPrompt(
        sentence,
        difficulty: TriggerDifficulty.master,
      );
      final interPrompt = QuickTriggerEngine.extractPrompt(
        sentence,
        difficulty: TriggerDifficulty.intermediate,
      );
      final beginPrompt = QuickTriggerEngine.extractPrompt(
        sentence,
        difficulty: TriggerDifficulty.beginner,
      );

      // 고급: 앞 3단어 ... 뒤 3단어
      expect(masterPrompt, equals("선생님 만약 가장 ... 주었다고 생각해 보십시오"));
      // 중급: 앞 4단어 ... 뒤 4단어
      expect(interPrompt, equals("선생님 만약 가장 절친한 ... 선물로 주었다고 생각해 보십시오"));
      // 초급: 앞 5단어 ... 뒤 5단어
      expect(beginPrompt, equals("선생님 만약 가장 절친한 친구가 ... 시계를 선물로 주었다고 생각해 보십시오"));

      // 단문 비중복 분기 검증
      const shortSentence = "하나님은 사랑이심이라";
      expect(QuickTriggerEngine.extractPrompt(shortSentence), equals("하나님은 사랑이심이라"));
    });
  });
}
