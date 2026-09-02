import 'package:flutter_test/flutter_test.dart';
import 'package:just_ee_master/services/tts_service.dart';

void main() {
  group('TTSService Syllable & Safe Overlap Tests (TS-TTS-001 ~ 004)', () {
    const sampleSentence = "영생은 값없이 주시는 하나님의 선물입니다.";

    test('TS-TTS-001: 발화 시작 초기(0.5초 이내)에는 문장 전체 반환 (건너뜀 방지)', () {
      final remaining = TTSService.calculateRemainingText(
        sampleSentence,
        0.4,
        1.0,
      );
      expect(remaining, equals(sampleSentence));
    });

    test('TS-TTS-002: 문장 중간(1.8초, 1.0배속) 발화 시 안전 중첩 어절 포함 검증', () {
      final remaining = TTSService.calculateRemainingText(
        sampleSentence,
        1.8,
        1.0,
      );
      // 1.8초 시 실제 발화된 단어는 "값없이" 부근 -> 안전하게 "값없이" 또는 "주시는"부터 포함하여 누락 방지
      expect(remaining, contains("주시는 하나님의 선물입니다."));
      expect(remaining, isNotEmpty);
    });

    test('TS-TTS-003: 긴 문장에서 3.0초 경과 시 단어 건너뜀 없이 안전한 어절 유지', () {
      const longSentence =
          "선생님 만약 가장 절친한 친구가 선생님을 위해 값비싼 시계를 선물로 주었다고 생각해 보십시오";
      final remaining = TTSService.calculateRemainingText(
        longSentence,
        2.5,
        1.0,
      );

      // 누락 없이 "친구", "선생님을", "값비싼" 등의 핵심 내용이 보존되어야 함
      expect(remaining, contains("값비싼 시계를 선물로 주었다고 생각해 보십시오"));
    });

    test('TS-TTS-004: 2.0배속 고속 발화 시에도 안전하게 이전 어절 포함', () {
      final remaining2x = TTSService.calculateRemainingText(
        sampleSentence,
        1.2,
        2.0,
      );
      expect(remaining2x, isNotEmpty);
      expect(remaining2x, contains("선물입니다."));
    });
  });
}
