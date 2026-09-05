import 'package:flutter_test/flutter_test.dart';
import 'package:just_ee_master/providers/scripture_provider.dart';
import 'package:just_ee_master/services/scripture_deck_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScriptureDeck Tests (TS-SCRIP-001 ~ TS-SCRIP-003)', () {
    test('TS-SCRIP-001: 8대 성경 구절 로드 및 카테고리/의미/빈칸 데이터 무결성 검증', () {
      final scriptures = ScriptureDeckEngine.getAllScriptures();
      expect(scriptures.length, equals(8));

      // 8대 핵심 구절 레퍼런스 검증
      expect(scriptures[0].reference, contains('요한일서 5장 13절'));
      expect(scriptures[1].reference, contains('에베소서 2장 8-9절'));
      expect(scriptures[2].reference, contains('로마서 3장 23절'));
      expect(scriptures[3].reference, contains('요한일서 4장 8절b'));
      expect(scriptures[4].reference, contains('출애굽기 34장 7절b'));
      expect(scriptures[5].reference, contains('이사야 53장 6절'));
      expect(scriptures[6].reference, contains('사도행전 16장 31절'));
      expect(scriptures[7].reference, contains('요한복음 6장 47절'));

      // 모든 구절이 비어있지 않고 빈칸 퀴즈 단어를 보유하는지 확인
      for (final s in scriptures) {
        expect(s.text.isNotEmpty, isTrue);
        expect(s.meaning.isNotEmpty, isTrue);
        expect(s.blankWords.isNotEmpty, isTrue);
      }
    });

    test('TS-SCRIP-002: ScriptureProvider 전체 성경덱 반복 재생(playAllRepeat) 토글 및 정지 검증', () async {
      final provider = ScriptureProvider();
      expect(provider.isPlaying, isFalse);
      expect(provider.currentIndex, equals(0));

      // 1. 반복 재생 시작
      final future = provider.playAllRepeat();
      expect(provider.isPlaying, isTrue);

      // 2. 정지 호출
      await provider.stopAudio();
      expect(provider.isPlaying, isFalse);

      await future;
      expect(provider.isPlaying, isFalse);

      // 3. togglePlayAllRepeat 동작 검증
      final toggleFuture = provider.togglePlayAllRepeat();
      expect(provider.isPlaying, isTrue);

      await provider.togglePlayAllRepeat();
      expect(provider.isPlaying, isFalse);

      await toggleFuture;
    });

    test('TS-SCRIP-003: 구절 순환(nextCard/prevCard/selectCard) 및 빈칸 퀴즈 모드 토글 검증', () {
      final provider = ScriptureProvider();
      expect(provider.currentIndex, equals(0));

      // 다음 구절
      provider.nextCard();
      expect(provider.currentIndex, equals(1));

      // 이전 구절
      provider.prevCard();
      expect(provider.currentIndex, equals(0));

      // 직접 선택
      provider.selectCard(5);
      expect(provider.currentIndex, equals(5));

      // 빈칸 퀴즈 모드 토글
      expect(provider.blankQuizMode, isFalse);
      provider.toggleBlankQuizMode();
      expect(provider.blankQuizMode, isTrue);
      provider.toggleBlankQuizMode();
      expect(provider.blankQuizMode, isFalse);

      // 텍스트 보이기/가리기 토글
      expect(provider.showText, isTrue);
      provider.toggleShowText();
      expect(provider.showText, isFalse);
      provider.toggleShowText();
      expect(provider.showText, isTrue);
    });
  });
}
