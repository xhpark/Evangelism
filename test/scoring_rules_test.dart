import 'package:flutter_test/flutter_test.dart';
import 'package:just_ee_master/services/scoring_engine.dart';
import 'package:just_ee_master/services/korean_text_normalizer.dart';

void main() {
  group('채점 어간 판정 규칙 (TS-SCORE-004 ~ 005)', () {
    test('TS-SCORE-004: 조사·어미 차이는 정답, 다른 단어는 오답으로 판정', () {
      // 조사만 다른 경우 → 정답
      expect(ScoringEngine.isSameWordStem('영생은', '영생을'), isTrue);
      expect(ScoringEngine.isSameWordStem('선물이', '선물을'), isTrue);
      // 어미가 이어진 경우 → 정답
      expect(ScoringEngine.isSameWordStem('주시', '주시는'), isTrue);

      // 앞 두 글자만 같고 실제로는 다른 단어 → 오답
      // (2026-08-29 이전에는 이런 경우도 정답으로 셌다)
      expect(ScoringEngine.isSameWordStem('선물입니다', '선반입니다'), isFalse);
      expect(ScoringEngine.isSameWordStem('영생은', '영원히'), isFalse);
      expect(ScoringEngine.isSameWordStem('하나님의', '하나둘'), isFalse);
    });

    test('TS-SCORE-005: 전혀 다른 발화는 낮은 점수, 정확한 발화는 만점', () {
      const original = '영생은 값없이 주시는 하나님의 선물입니다';
      const keywords = ['영생', '값없이', '하나님', '선물'];

      final perfect = ScoringEngine.calculateScore(
        examId: 't1',
        title: 't',
        originalText: original,
        spokenText: original,
        keywords: keywords,
      );
      expect(perfect.totalScore, equals(100.0));

      final wrong = ScoringEngine.calculateScore(
        examId: 't2',
        title: 't',
        originalText: original,
        spokenText: '오늘 날씨가 매우 좋아서 산책을 나갔습니다',
        keywords: keywords,
      );
      expect(wrong.totalScore, lessThan(30.0));
    });
  });

  group('한국어 정규화 안전성 (TS-NORM-004 ~ 005)', () {
    test('TS-NORM-004: 지시어·감탄사를 대본에서 지우지 않는다', () {
      // '그', '이', '아'는 대본에 실제로 쓰이는 낱말이라 삭제하면 안 된다.
      expect(KoreanTextNormalizer.normalize('그 은혜에 의하여 구원을 받았으니'),
          contains('그 은혜에'));
      expect(KoreanTextNormalizer.normalize('아 그러시군요'), contains('아'));

      // 실제 추임새는 계속 제거한다.
      expect(KoreanTextNormalizer.normalize('어... 음... 영생은 선물입니다'),
          equals('영생은 선물입니다'));
    });

    test('TS-NORM-005: 장/절 수사만 숫자로 바꾸고 일반 낱말은 보존한다', () {
      expect(KoreanTextNormalizer.normalize('요한복음 삼장 십육절'),
          equals('요한복음 3장 16절'));
      expect(KoreanTextNormalizer.normalize('이사야 오십삼장 육절'),
          equals('이사야 53장 6절'));

      // '사장님', '일절'은 그대로 (이전에는 '4장님', '1절'로 깨졌다)
      final result = KoreanTextNormalizer.normalize('이 사장님은 일절 관여하지 않습니다');
      expect(result, contains('사장님은'));
      expect(result, contains('일절'));
    });
  });

  group('긴 지문 비동기 채점 (TS-SCORE-006)', () {
    test('TS-SCORE-006: 전체 완주 분량 지문도 아이솔레이트에서 정상 채점된다', () async {
      // 전체 완주 시험 지문(7,000자 이상)을 동기 채점하면 UI가 약 2초 멈춘다.
      // compute() 아이솔레이트 경로가 실제로 동작하는지(커스텀 객체 전달 포함) 확인한다.
      final long = List.filled(200, '영생은 값없이 주시는 하나님의 선물입니다').join(' ');
      expect(long.length, greaterThan(800));

      final result = await ScoringEngine.calculateScoreAsync(
        examId: 'long',
        title: '전체 완주',
        originalText: long,
        spokenText: long,
        keywords: const ['영생', '선물'],
      );

      expect(result.totalScore, equals(100.0));
      expect(result.diffTokens, isNotEmpty);

      // 절반만 발화한 경우에도 결과가 돌아와야 한다.
      final partial = await ScoringEngine.calculateScoreAsync(
        examId: 'long2',
        title: '전체 완주',
        originalText: long,
        spokenText: long.substring(0, long.length ~/ 2),
        keywords: const ['영생', '선물'],
      );
      expect(partial.totalScore, lessThan(100.0));
      expect(partial.totalScore, greaterThan(0.0));
    });
  });
}
