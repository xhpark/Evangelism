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
            final lowerLocale = locale.toLowerCase().replaceAll('_', '-');
            final lowerName = name.toLowerCase().replaceAll('_', '-');

            // 인도 콩카니어(kok / kok-IN) 제외 및 순수 한국어(ko / kor / ko-KR)만 추출
            final isKorean = (lowerLocale.startsWith('ko-') ||
                    lowerLocale == 'ko' ||
                    lowerLocale.startsWith('kor') ||
                    lowerName.contains('ko-kr') ||
                    lowerName.contains('kokr')) &&
                !lowerLocale.startsWith('kok') &&
                !lowerName.contains('kok-in') &&
                !lowerName.contains('kok');

            if (isKorean) {
              String friendlyName;
              if (lowerName.contains('koc') || lowerName.contains('female1') || lowerName.contains('f00')) {
                friendlyName = "보이스 $index (구글 자연스러운 여성 톤 C)";
              } else if (lowerName.contains('kob') || lowerName.contains('female2') || lowerName.contains('f01')) {
                friendlyName = "보이스 $index (구글 부드러운 여성 톤 B)";
              } else if (lowerName.contains('koe')) {
                friendlyName = "보이스 $index (구글 차분한 여성 톤 E)";
              } else if (lowerName.contains('kod') || lowerName.contains('male1') || lowerName.contains('m00')) {
                friendlyName = "보이스 $index (구글 신뢰감 있는 남성 톤 D)";
              } else if (lowerName.contains('ism')) {
                friendlyName = "보이스 $index (구글 또렷한 남성 톤 A)";
              } else if (lowerName.contains('kof')) {
                friendlyName = "보이스 $index (구글 중후한 남성 톤 F)";
              } else if (lowerName.contains('smt')) {
                friendlyName = "보이스 $index (삼성 고품질 보이스)";
              } else if (lowerName.contains('language') || lowerName.contains('default')) {
                friendlyName = "보이스 $index (삼성 기본 보이스)";
              } else if (lowerName.contains('woman') || lowerName.contains('female')) {
                friendlyName = "보이스 $index (한국어 여성 톤)";
              } else if (lowerName.contains('man') || lowerName.contains('male')) {
                friendlyName = "보이스 $index (한국어 남성 톤)";
              } else {
                friendlyName = "보이스 $index (한국어 표준 보이스)";
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
          name: 'ko-kr-default',
          locale: 'ko-KR',
          displayName: '기본 고품질 한국어 보이스',
        ));
      }

      _availableVoices = list;

      if (_selectedVoiceName.isEmpty && list.isNotEmpty) {
        _selectedVoiceName = list.first.name;
      }

      // 저장된 보이스 적용
      if (_selectedVoiceName.isNotEmpty) {
        final match = list.where((v) => v.name == _selectedVoiceName);
        if (match.isNotEmpty) {
          await _tts.setVoice({"name": match.first.name, "locale": match.first.locale});
        } else if (list.isNotEmpty) {
          _selectedVoiceName = list.first.name;
          await _tts.setVoice({"name": list.first.name, "locale": list.first.locale});
        }
      }

      return list;
    } catch (_) {
      return [];
    }
  }

  /// 보이스 목록 수동 재동기화
  Future<List<TTSVoiceInfo>> refreshVoices() async {
    return await _loadAndSetKoreanVoices();
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

  /// 발화 전 최신 보이스/음높이/속도 설정 적용
  Future<void> _applyTtsSettings() async {
    try {
      await _tts.setLanguage('ko-KR');
      await _tts.setPitch(_pitch);
      final adjustedRate = (0.50 + (_speedRate - 1.0) * 0.35).clamp(0.25, 1.0);
      await _tts.setSpeechRate(adjustedRate);
      if (_selectedVoiceName.isNotEmpty && _availableVoices.isNotEmpty) {
        final match = _availableVoices.where((v) => v.name == _selectedVoiceName);
        if (match.isNotEmpty) {
          await _tts.setVoice({"name": match.first.name, "locale": match.first.locale});
        }
      }
    } catch (_) {}
  }

  /// 샘플 문장 미리듣기
  Future<void> previewVoice() async {
    await initialize();
    const sample = "안녕하세요. 영생은 값없이 주시는 하나님의 선물입니다.";
    await stop();
    await _applyTtsSettings();
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

    await _applyTtsSettings();
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
