import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/scripture_deck_engine.dart';
import '../services/tts_service.dart';
import '../services/device_helper_service.dart';

class ScriptureProvider extends ChangeNotifier {
  final TTSService _tts = TTSService();
  List<ScriptureCard> _cards = [];
  int _currentIndex = 0;
  bool _showText = true;
  bool _blankQuizMode = false;
  bool _isPlaying = false;
  int _playbackSessionId = 0;
  bool _isDisposed = false;

  ScriptureProvider() {
    _cards = ScriptureDeckEngine.getAllScriptures();
    _tts.initialize();
  }

  List<ScriptureCard> get cards => _cards;
  int get currentIndex => _currentIndex;
  bool get showText => _showText;
  bool get blankQuizMode => _blankQuizMode;
  bool get isPlaying => _isPlaying;

  ScriptureCard? get currentCard =>
      (_cards.isNotEmpty && _currentIndex < _cards.length)
      ? _cards[_currentIndex]
      : null;

  void toggleShowText() {
    _showText = !_showText;
    notifyListeners();
  }

  void toggleBlankQuizMode() {
    _blankQuizMode = !_blankQuizMode;
    notifyListeners();
  }

  void nextCard() {
    if (_currentIndex + 1 < _cards.length) {
      _currentIndex++;
      _showText = true;
      if (_isPlaying) {
        playAllRepeat(fromIndex: _currentIndex);
      } else {
        notifyListeners();
      }
    }
  }

  void prevCard() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _showText = true;
      if (_isPlaying) {
        playAllRepeat(fromIndex: _currentIndex);
      } else {
        notifyListeners();
      }
    }
  }

  void selectCard(int index) {
    if (index >= 0 && index < _cards.length) {
      _currentIndex = index;
      _showText = true;
      if (_isPlaying) {
        playAllRepeat(fromIndex: index);
      } else {
        notifyListeners();
      }
    }
  }

  /// 전체 성경덱 반복 재생 토글
  Future<void> togglePlayAllRepeat() async {
    if (_isPlaying) {
      await stopAudio();
    } else {
      await playAllRepeat(fromIndex: _currentIndex);
    }
  }

  /// 전체 성경덱 무한 반복 재생
  Future<void> playAllRepeat({int? fromIndex}) async {
    if (_cards.isEmpty) return;

    _isPlaying = true;
    _playbackSessionId++;
    final session = _playbackSessionId;

    await DeviceHelperService.enableKeepScreenOn();
    notifyListeners();

    int startIndex = fromIndex ?? _currentIndex;
    if (startIndex < 0 || startIndex >= _cards.length) {
      startIndex = 0;
    }

    while (_isPlaying && _playbackSessionId == session && !_isDisposed) {
      for (int i = startIndex; i < _cards.length; i++) {
        if (!_isPlaying || _playbackSessionId != session || _isDisposed) break;

        _currentIndex = i;
        notifyListeners();

        final card = _cards[i];
        final text = "${card.reference}. ${card.text}";

        await _tts.speak(text);

        if (!_isPlaying || _playbackSessionId != session || _isDisposed) break;
        await Future.delayed(const Duration(milliseconds: 600));
      }
      startIndex = 0; // 8구절 완주 후 1번째 구절부터 다시 무한 반복
    }

    if (_playbackSessionId == session) {
      _isPlaying = false;
      await DeviceHelperService.disableKeepScreenOn();
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  /// 오디오 재생 중단
  Future<void> stopAudio() async {
    _isPlaying = false;
    _playbackSessionId++;
    try {
      await _tts.stop();
    } catch (_) {}
    await DeviceHelperService.disableKeepScreenOn();
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// 단일 구절 1회 듣기
  Future<void> speakSingleVerse([int? index]) async {
    final targetIdx = index ?? _currentIndex;
    if (targetIdx >= 0 && targetIdx < _cards.length) {
      await stopAudio();
      _currentIndex = targetIdx;
      notifyListeners();
      final card = _cards[targetIdx];
      final text = "${card.reference}. ${card.text}";
      await _tts.speak(text);
    }
  }

  /// 스피커 터치 시 전체 반복 재생 실행
  Future<void> speakCurrentVerse() async {
    await togglePlayAllRepeat();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _isPlaying = false;
    _playbackSessionId++;
    try {
      _tts.stop();
    } catch (_) {}
    DeviceHelperService.disableKeepScreenOn();
    super.dispose();
  }
}
