import 'package:flutter/foundation.dart';
import '../services/scripture_deck_engine.dart';
import '../services/tts_service.dart';

class ScriptureProvider extends ChangeNotifier {
  final TTSService _tts = TTSService();
  List<ScriptureCard> _cards = [];
  int _currentIndex = 0;
  bool _showText = true;
  bool _blankQuizMode = false;

  ScriptureProvider() {
    _cards = ScriptureDeckEngine.getAllScriptures();
    _tts.initialize();
  }

  List<ScriptureCard> get cards => _cards;
  int get currentIndex => _currentIndex;
  bool get showText => _showText;
  bool get blankQuizMode => _blankQuizMode;

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
      notifyListeners();
    }
  }

  void prevCard() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _showText = true;
      notifyListeners();
    }
  }

  void selectCard(int index) {
    if (index >= 0 && index < _cards.length) {
      _currentIndex = index;
      _showText = true;
      notifyListeners();
    }
  }

  Future<void> speakCurrentVerse() async {
    if (currentCard != null) {
      final text = "${currentCard!.reference}. ${currentCard!.text}";
      await _tts.speak(text);
    }
  }
}
