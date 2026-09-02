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

    test('TS-TRIG-003: 난이도별 프리셋 시간(1.0s, 2.0s, 3.0s) 검증', () {
      expect(TriggerDifficulty.master.durationSeconds, equals(1.0));
      expect(TriggerDifficulty.intermediate.durationSeconds, equals(2.0));
      expect(TriggerDifficulty.beginner.durationSeconds, equals(3.0));
    });
  });
}
