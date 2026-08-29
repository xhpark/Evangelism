import 'package:flutter_test/flutter_test.dart';
import 'package:just_ee_master/services/korean_text_normalizer.dart';

void main() {
  group('KoreanTextNormalizer Tests (TS-NORM-001, TS-NORM-002)', () {
    test('TS-NORM-001: 추임새 및 간투사 자동 필터링 검증', () {
      const input = "어... 영생은 저... 값없이 주시는 하나님의 음... 선물입니다.";
      final normalized = KoreanTextNormalizer.normalize(input);

      expect(normalized, contains("영생은"));
      expect(normalized, contains("값없이"));
      expect(normalized, contains("하나님의"));
      expect(normalized, contains("선물입니다"));
      expect(normalized.contains("어..."), isFalse);
      expect(normalized.contains("음..."), isFalse);
    });

    test('TS-NORM-002: 성경 장/절 및 한글 수사 아라비아 숫자 통일 변환', () {
      const input = "에베소서 이장 팔절 구절";
      final normalized = KoreanTextNormalizer.normalizeScriptureRef(input);

      expect(normalized, contains("2장"));
      expect(normalized, contains("8절"));
      expect(normalized, contains("9절"));
    });

    test('TS-NORM-003: 특수문자 및 다중 공백 제거 정제 검증', () {
      const input = "  영생은,  돈이나!   공로나??  자격으로   얻는 것이 아닙니다...  ";
      final normalized = KoreanTextNormalizer.normalize(input);

      expect(normalized, equals("영생은 돈이나 공로나 자격으로 얻는 것이 아닙니다"));
    });
  });
}
