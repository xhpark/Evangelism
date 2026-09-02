import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_ee_master/data/script_repository.dart';
import 'package:just_ee_master/services/transition_sentence_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TransitionSentenceEngine Tests (TS-TRANS-001 ~ 002)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('TS-TRANS-001: 6대 대지 전환문장 무결성 및 순서 검증', () async {
      final sections = await ScriptRepository().loadSections();
      final list = TransitionSentenceEngine.buildFromSections(sections);

      expect(list.length, equals(6));

      for (int i = 0; i < 6; i++) {
        expect(list[i].index, equals(i + 1));
        expect(list[i].transitionScript, isNotEmpty);
        expect(list[i].leadIn, isNotEmpty);
        expect(list[i].keywords, isNotEmpty);
        expect(list[i].stepId, isNotEmpty);
      }

      // 대지 순서대로 배치되는지 확인
      expect(
        list.map((t) => t.stepId).toList(),
        equals([
          'intro_6',
          'grace_4',
          'human_5',
          'god_4',
          'christ_5',
          'faith_4',
        ]),
      );
    });

    test('TS-TRANS-002: 전환문장이 실제 교재 대본 안에 포함되어 있는지 검증', () async {
      final sections = await ScriptRepository().loadSections();
      final list = TransitionSentenceEngine.buildFromSections(sections);
      final stepMap = {
        for (final sec in sections)
          for (final st in sec.steps) st.stepId: st,
      };

      // 목록에 보여주는 전환문장은 반드시 해당 단락 대본의 일부여야 한다.
      // (하드코딩 목록과 대본이 어긋나 훈련생이 다른 문장을 외우던 문제 방지)
      for (final item in list) {
        final step = stepMap[item.stepId]!;
        expect(
          step.effectiveScript.contains(item.transitionScript),
          isTrue,
          reason: '${item.stepId}의 전환문장이 대본과 일치하지 않습니다.',
        );
      }
    });
  });
}
