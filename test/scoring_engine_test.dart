import 'package:flutter_test/flutter_test.dart';
import 'package:just_ee_master/models/diff_token.dart';
import 'package:just_ee_master/services/scoring_engine.dart';

void main() {
  group('ScoringEngine Tests (TS-SCORE-001, TS-SCORE-002, TS-SCORE-003)', () {
    test('TS-SCORE-001: 100% 일치 발화 채점', () {
      const orig = "영생은 값없이 주시는 하나님의 선물입니다.";
      const spoken = "영생은 값없이 주시는 하나님의 선물입니다";
      final kw = ["영생", "값없이", "하나님", "선물"];

      final result = ScoringEngine.calculateScore(
        examId: 'test_1',
        title: '은혜 테스트',
        originalText: orig,
        spokenText: spoken,
        keywords: kw,
      );

      expect(result.totalScore, equals(100.0));
      expect(result.isPassed, isTrue);
      expect(result.diffTokens.every((t) => t.type == DiffType.matched), isTrue);
    });

    test('TS-SCORE-002: 핵심 키워드 누락 시 가중치 감점 및 Missing 토큰 마킹', () {
      const orig = "영생은 돈이나 공로나 자격으로 얻는 것이 아닙니다.";
      const spoken = "영생은 공로나 자격으로 얻는 게 아니에요."; // '돈' 누락
      final kw = ["돈", "공로", "자격"];

      final result = ScoringEngine.calculateScore(
        examId: 'test_2',
        title: '은혜 키워드 테스트',
        originalText: orig,
        spokenText: spoken,
        keywords: kw,
      );

      expect(result.totalScore, lessThan(95.0));
      expect(result.totalScore, greaterThan(55.0));
      // '돈이나' 누락 마킹 확인
      expect(result.diffTokens.any((t) => t.type == DiffType.missing && t.text.contains("돈")), isTrue);
    });

    test('TS-SCORE-003: 빈 문자열 발화 시 0점 및 전체 Missing 처리', () {
      const orig = "인간은 죄인입니다.";
      const spoken = "";

      final result = ScoringEngine.calculateScore(
        examId: 'test_3',
        title: '공백 테스트',
        originalText: orig,
        spokenText: spoken,
      );

      expect(result.totalScore, equals(0.0));
      expect(result.isPassed, isFalse);
      expect(result.diffTokens.every((t) => t.type == DiffType.missing), isTrue);
    });
  });
}
