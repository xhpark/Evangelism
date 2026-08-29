import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PlayMode {
  singleRepeat, // 1문장 무한 반복
  sectionPlay, // 현재 섹션 1회 재생
  sectionRepeat, // 현재 섹션 무한 반복 재생
  allSequentialPlay, // 서론부터 양육까지 전체 연속 재생
}

class TTSVoiceInfo {
  final String name;
  final String locale;
  final String displayName;

  TTSVoiceInfo({
    required this.name,
    required this.locale,
    required this.displayName,
  });
}

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isPlaying = false;
  double _speedRate = 1.0;
  double _pitch = 1.0;
  String _selectedVoiceName = '';
  PlayMode _playMode = PlayMode.sectionRepeat;

  List<TTSVoiceInfo> _availableVoices = [];

  String _currentSpeakingText = '';
  final Stopwatch _speechStopwatch = Stopwatch();

  Function(String stepId)? onStepStarted;
  Function(String stepId)? onStepCompleted;
  Function()? onAllCompleted;

  bool get isPlaying => _isPlaying;
  double get speedRate => _speedRate;
  double get pitch => _pitch;
  String get selectedVoiceName => _selectedVoiceName;
  List<TTSVoiceInfo> get availableVoices => _availableVoices;
  PlayMode get playMode => _playMode;
  String get currentSpeakingText => _currentSpeakingText;

  static const String _prefVoiceKey = 'just_ee_tts_voice_name';
  static const String _prefPitchKey = 'just_ee_tts_pitch';

  /// 음절 기반 잔여 텍스트 계산
  static String calculateRemainingText(
      String fullText, double elapsedSeconds, double currentSpeed) {
    final text = fullText.trim();
    if (text.isEmpty) return text;

    final actualAudioSeconds = elapsedSeconds - 0.45;
    if (actualAudioSeconds <= 0.3) {
      return text;
    }

    final words = text.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.length <= 2) return text;

    final syllablesPerSec = 5.0 * currentSpeed;
    final elapsedSyllables = actualAudioSeconds * syllablesPerSec;

    int accumulatedSyllables = 0;
    int targetWordIndex = 0;

    for (int i = 0; i < words.length; i++) {
      final wordSyllables =
          words[i].replaceAll(RegExp(r'[^가-힣0-9a-zA-Z]'), '').length;
      final effectiveCount = wordSyllables > 0 ? wordSyllables : 1;

      if (accumulatedSyllables + effectiveCount >= elapsedSyllables) {
        targetWordIndex = (i > 0) ? (i - 1) : 0;
        break;
      }
      accumulatedSyllables += effectiveCount;
      targetWordIndex = (i > 0) ? (i - 1) : 0;
    }

    if (targetWordIndex >= words.length) {
      targetWordIndex = (words.length > 1) ? (words.length - 2) : 0;
    }

    return words.sublist(targetWordIndex).join(' ').trim();
  }

  String getRemainingText() {
    final elapsedSec = _speechStopwatch.elapsedMilliseconds / 1000.0;
    return calculateRemainingText(_currentSpeakingText, elapsedSec, _speedRate);
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedVoiceName = prefs.getString(_prefVoiceKey) ?? '';
      _pitch = prefs.getDouble(_prefPitchKey) ?? 1.0;

      await _tts.setLanguage('ko-KR');
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(_pitch);
      await _tts.awaitSpeakCompletion(true);

      await _loadAndSetKoreanVoices();
    } catch (_) {
      // 단위 테스트 또는 비네이티브 환경에서 안전하게 통과
    }

    _tts.setStartHandler(() {
      _isPlaying = true;
      _speechStopwatch.reset();
      _speechStopwatch.start();
    });

    _tts.setCompletionHandler(() {
      _isPlaying = false;
      _speechStopwatch.stop();
    });

    _tts.setErrorHandler((msg) {
      _isPlaying = false;
      _speechStopwatch.stop();
    });

    _isInitialized = true;
  }

  /// 기기에 설치된 한국어 TTS 보이스 목록 검색 및 로드
  Future<List<TTSVoiceInfo>> _loadAndSetKoreanVoices() async {
    try {
      final dynamic rawVoices = await _tts.getVoices;
      final List<TTSVoiceInfo> list = [];

      if (rawVoices is List) {
        int index = 1;
        for (final v in rawVoices) {
          if (v is Map) {
            final name = v['name']?.toString() ?? '';
            final locale = v['locale']?.toString() ?? '';

            if (locale.toLowerCase().contains('ko') || name.toLowerCase().contains('ko')) {
              String friendlyName;
              if (name.contains('koc') || name.contains('woman') || name.contains('female')) {
                friendlyName = "보이스 $index (자연스러운 여성 톤)";
              } else if (name.contains('kod') || name.contains('ism') || name.contains('male')) {
                friendlyName = "보이스 $index (신뢰감 있는 남성 톤)";
              } else {
                friendlyName = "보이스 $index ($name)";
              }

              list.add(TTSVoiceInfo(
                name: name,
                locale: locale.isEmpty ? 'ko-KR' : locale,
                displayName: friendlyName,
              ));
              index++;
            }
          }
        }
      }

      if (list.isEmpty) {
        list.add(TTSVoiceInfo(
          name: 'ko-KR-default',
          locale: 'ko-KR',
          displayName: '기본 고품질 한국어 보이스',
        ));
      }

      _availableVoices = list;

      // 저장된 보이스가 목록에 있으면 적용, 없으면 첫 번째 보이스 적용
      if (_selectedVoiceName.isNotEmpty) {
        final match = list.where((v) => v.name == _selectedVoiceName);
        if (match.isNotEmpty) {
          await _tts.setVoice({"name": match.first.name, "locale": match.first.locale});
        }
      }

      return list;
    } catch (_) {
      return [];
    }
  }

  /// 보이스 변경 및 영구 저장
  Future<void> setVoice(TTSVoiceInfo voice) async {
    _selectedVoiceName = voice.name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefVoiceKey, voice.name);

    try {
      await _tts.setVoice({"name": voice.name, "locale": voice.locale});
    } catch (_) {}
  }

  /// 음높이(톤) 조절 (0.7 저음 ~ 1.3 고음)
  Future<void> setPitch(double pitchVal) async {
    _pitch = pitchVal.clamp(0.6, 1.4);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefPitchKey, _pitch);

    try {
      await _tts.setPitch(_pitch);
    } catch (_) {}
  }

  /// 샘플 문장 미리듣기
  Future<void> previewVoice() async {
    await initialize();
    const sample = "안녕하세요. 영생은 값없이 주시는 하나님의 선물입니다.";
    await stop();
    await _tts.speak(sample);
  }

  /// 배속 설정 (0.8x, 1.0x, 1.5x, 2.0x, 2.5x)
  Future<void> setSpeedRate(double rate) async {
    _speedRate = rate.clamp(0.5, 3.0);
    final adjustedRate = (0.50 + (_speedRate - 1.0) * 0.35).clamp(0.25, 1.0);
    await _tts.setSpeechRate(adjustedRate);
  }

  void setPlayMode(PlayMode mode) {
    _playMode = mode;
  }

  /// 단일 문장 발화
  Future<void> speak(String text, {String? stepId}) async {
    await initialize();
    if (stepId != null) {
      onStepStarted?.call(stepId);
    }

    _currentSpeakingText = text;
    _isPlaying = true;
    _speechStopwatch.reset();
    _speechStopwatch.start();

    await _tts.speak(text);

    _isPlaying = false;
    _speechStopwatch.stop();

    if (stepId != null) {
      onStepCompleted?.call(stepId);
    }
  }

  /// 재생 정지
  Future<void> stop() async {
    _isPlaying = false;
    _speechStopwatch.stop();
    await _tts.stop();
  }

  Future<void> pause() async {
    _isPlaying = false;
    _speechStopwatch.stop();
    await _tts.pause();
  }
}
