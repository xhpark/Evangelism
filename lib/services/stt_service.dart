import 'package:speech_to_text/speech_to_text.dart';

class STTService {
  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;
  String _recognizedText = '';
  String _previousBuffer = ''; // 세그먼트 연결용 버퍼

  Function(String text)? onResultChanged;
  Function(double level)? onSoundLevelChanged;
  Function()? onListeningStopped;

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  String get recognizedText => _recognizedText;

  Future<bool> initialize() async {
    if (_isAvailable) return true;

    try {
      _isAvailable = await _speech.initialize(
        onError: (val) {
          _isListening = false;
          onListeningStopped?.call();
        },
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            _isListening = false;
            onListeningStopped?.call();
          }
        },
      );
      return _isAvailable;
    } catch (_) {
      _isAvailable = false;
      return false;
    }
  }

  /// 수음 시작 (세그먼트 스티칭 지원)
  Future<void> startListening({bool clearBuffer = true}) async {
    final available = await initialize();
    if (!available) return;

    if (clearBuffer) {
      _recognizedText = '';
      _previousBuffer = '';
    } else {
      if (_recognizedText.isNotEmpty) {
        _previousBuffer = '$_recognizedText ';
      }
    }

    _isListening = true;

    await _speech.listen(
      onResult: (result) {
        final currentText = result.recognizedWords;
        _recognizedText = '$_previousBuffer$currentText'.trim();
        onResultChanged?.call(_recognizedText);
      },
      onSoundLevelChange: (level) {
        onSoundLevelChanged?.call(level);
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
        listenFor: const Duration(minutes: 10),
        pauseFor: const Duration(seconds: 4),
      ),
    );
  }

  /// 수음 정지
  Future<void> stopListening() async {
    _isListening = false;
    await _speech.stop();
    onListeningStopped?.call();
  }

  /// 수음 취소
  Future<void> cancel() async {
    _isListening = false;
    await _speech.cancel();
  }
}
