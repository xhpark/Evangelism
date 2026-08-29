import 'package:flutter_test/flutter_test.dart';
import 'package:just_ee_master/services/transition_sentence_engine.dart';

void main() {
  group('TransitionSentenceEngine Tests (TS-TRANS-001)', () {
    test('TS-TRANS-001: 6대 대지 전환문장 무결성 및 순서 검증', () {
      final list = TransitionSentenceEngine.getAllTransitions();
      expect(list.length, equals(6));

      // 6개 전환문장이 1~6 순서로 배치되어 있는지 확인
      for (int i = 0; i < 6; i++) {
        expect(list[i].index, equals(i + 1));
        expect(list[i].transitionScript, isNotEmpty);
        expect(list[i].leadIn, isNotEmpty);
        expect(list[i].keywords, isNotEmpty);
      }
    });
  });
}
