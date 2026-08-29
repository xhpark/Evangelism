import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';

/// 안드로이드 음성 인식기는 단말에 하나뿐이고 `speech_to_text` 패키지도 싱글턴이므로,
/// 본 래퍼도 싱글턴으로 유지한다. (탭마다 별도 인스턴스를 만들면 먼저 초기화한 쪽이
/// 상태 콜백을 선점해 다른 탭이 '수음 중'에서 멈추는 문제가 발생한다.)
class STTService {
  static final STTService _instance = STTService._internal();
  factory STTService() => _instance;
  STTService._internal();

  final SpeechToText _speech = SpeechToText();

  bool _pluginReady = false;
  bool _isListening = false;
  String _recognizedText = '';
  String _previousBuffer = '';
  String? _koreanLocaleId;

  /// 침묵으로 인식기가 스스로 멈췄을 때 자동으로 다시 수음할지 여부
  bool _keepAlive = false;
  int _autoRestartCount = 0;
  static const int _maxAutoRestarts = 60; // 4초 침묵 기준 최대 약 10분 이상 커버

  // 현재 수음 세션의 소유자(탭) 콜백
  void Function(String text)? _onResult;
  void Function(double level)? _onLevel;
  void Function()? _onStopped;
  void Function(String message)? _onError;

  bool get isListening => _isListening;
  String get recognizedText => _recognizedText;

  /// 플러그인 초기화. 상태/오류 콜백은 이 래퍼가 단 한 번만 등록하고,
  /// 실제 처리는 현재 수음 세션 소유자에게 위임한다.
  Future<bool> _ensureInitialized() async {
    if (_pluginReady) return true;

    try {
      _pluginReady = await _speech.initialize(
        onError: (err) {
          _handleEngineStopped(errorMsg: err.errorMsg);
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _handleEngineStopped();
          }
        },
      );
    } catch (_) {
      _pluginReady = false;
    }

    if (_pluginReady && _koreanLocaleId == null) {
      try {
        final locales = await _speech.locales();
        final ko = locales.where((l) =>
            l.localeId.toLowerCase().replaceAll('-', '_').startsWith('ko'));
        if (ko.isNotEmpty) _koreanLocaleId = ko.first.localeId;
      } catch (_) {
        _koreanLocaleId = null;
      }
    }

    return _pluginReady;
  }

  /// 인식기가 멈췄을 때: 자동 재개 대상이면 이어서 다시 듣고, 아니면 소유자에게 알린다.
  void _handleEngineStopped({String? errorMsg}) {
    if (!_isListening) return;

    final isFatal = errorMsg != null &&
        (errorMsg.contains('permission') ||
            errorMsg.contains('audio') ||
            errorMsg.contains('client'));

    if (_keepAlive && !isFatal && _autoRestartCount < _maxAutoRestarts) {
      _autoRestartCount++;
      // 발화 중간의 침묵으로 끊긴 것이므로 지금까지의 인식 결과를 이어붙여 재개한다.
      unawaited(_listenInternal(continueSession: true));
      return;
    }

    _isListening = false;
    _keepAlive = false;
    if (errorMsg != null) {
      _onError?.call(_toKoreanMessage(errorMsg));
    }
    _onStopped?.call();
  }

  String _toKoreanMessage(String raw) {
    if (raw.contains('permission')) {
      return '마이크 권한이 없어 음성 인식을 시작할 수 없습니다. 설정에서 마이크 권한을 허용해 주세요.';
    }
    if (raw.contains('no_match') || raw.contains('speech_timeout')) {
      return '음성이 인식되지 않았습니다. 마이크에 조금 더 가까이서 또렷하게 말씀해 주세요.';
    }
    if (raw.contains('network')) {
      return '네트워크 음성 인식에 실패했습니다. 오프라인 한국어 인식 데이터를 설치하면 안정적입니다.';
    }
    return '음성 인식 오류가 발생했습니다. ($raw)';
  }

  Future<void> _listenInternal({required bool continueSession}) async {
    if (continueSession && _recognizedText.isNotEmpty) {
      _previousBuffer = '$_recognizedText ';
    }

    await _speech.listen(
      onResult: (result) {
        _recognizedText = '$_previousBuffer${result.recognizedWords}'.trim();
        _onResult?.call(_recognizedText);
      },
      onSoundLevelChange: (level) => _onLevel?.call(level),
      listenOptions: SpeechListenOptions(
        localeId: _koreanLocaleId,
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
        listenFor: const Duration(minutes: 10),
        pauseFor: const Duration(seconds: 4),
      ),
    );
  }

  /// 수음 시작. [keepAlive]가 참이면 침묵으로 인식기가 멈춰도
  /// 이전 인식 결과에 이어서 자동으로 재개한다(장문 암송 시험용 세그먼트 스티칭).
  /// 시작에 실패하면 false를 돌려주고 [onError]로 사유를 전달한다.
  Future<bool> startListening({
    bool keepAlive = false,
    void Function(String text)? onResult,
    void Function(double level)? onLevel,
    void Function()? onStopped,
    void Function(String message)? onError,
  }) async {
    _onResult = onResult;
    _onLevel = onLevel;
    _onStopped = onStopped;
    _onError = onError;

    final ready = await _ensureInitialized();
    if (!ready) {
      _isListening = false;
      _onError?.call(
          '이 기기에서 음성 인식을 사용할 수 없습니다. 마이크 권한과 구글 음성 인식 설치 상태를 확인해 주세요.');
      return false;
    }

    _recognizedText = '';
    _previousBuffer = '';
    _autoRestartCount = 0;
    _keepAlive = keepAlive;
    _isListening = true;

    try {
      await _listenInternal(continueSession: false);
      return true;
    } catch (e) {
      _isListening = false;
      _keepAlive = false;
      _onError?.call('음성 인식을 시작하지 못했습니다. ($e)');
      return false;
    }
  }

  /// 사용자가 명시적으로 종료 (결과 유지)
  Future<void> stopListening() async {
    if (!_isListening) return;
    _keepAlive = false;
    _isListening = false;
    try {
      await _speech.stop();
    } catch (_) {}
    _onStopped?.call();
  }

  /// 취소 (결과 폐기)
  Future<void> cancel() async {
    _keepAlive = false;
    _isListening = false;
    _recognizedText = '';
    _previousBuffer = '';
    try {
      await _speech.cancel();
    } catch (_) {}
  }
}
