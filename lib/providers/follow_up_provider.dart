import 'package:flutter/foundation.dart';
import '../models/follow_up_model.dart';
import '../services/follow_up_engine.dart';
import '../services/tts_service.dart';
import '../services/stt_service.dart';

class FollowUpProvider extends ChangeNotifier {
  final TTSService _tts = TTSService();
  final STTService _stt = STTService();

  int _currentStepIndex = 0; // 0: 생일축하, 1: 확신 4질문, 2: 5손가락, 3: 약속/책자
  int _currentQnAIndex = 0; // 확신 4문답 인덱스 (0~3)
  int _selectedFingerIndex = 1; // 1~5

  bool _isSpeaking = false;
  bool _isListening = false;
  String _userSpokenText = '';
  QnAEvaluationResult? _lastQnAResult;

  FollowUpProvider() {
    _init();
  }

  int get currentStepIndex => _currentStepIndex;
  int get currentQnAIndex => _currentQnAIndex;
  int get selectedFingerIndex => _selectedFingerIndex;
  bool get isSpeaking => _isSpeaking;
  bool get isListening => _isListening;
  String get userSpokenText => _userSpokenText;
  QnAEvaluationResult? get lastQnAResult => _lastQnAResult;

  DialoguePair get currentDialoguePair =>
      FollowUpData.assuranceQnAList[_currentQnAIndex];

  GrowthPrinciple get currentGrowthPrinciple =>
      FollowUpData.growthPrinciples[_selectedFingerIndex - 1];

  Future<void> _init() async {
    await _tts.initialize();
    await _stt.initialize();

    _stt.onResultChanged = (text) {
      _userSpokenText = text;
      notifyListeners();
    };

    _stt.onListeningStopped = () {
      _isListening = false;
      _evaluateCurrentSpoken();
      notifyListeners();
    };
  }

  void selectStep(int step) {
    _currentStepIndex = step;
    _userSpokenText = '';
    _lastQnAResult = null;
    notifyListeners();
  }

  void selectFinger(int fingerIndex) {
    _selectedFingerIndex = fingerIndex.clamp(1, 5);
    notifyListeners();
    speakSelectedPrinciple();
  }

  /// 파트너(새신자) 질문 음성 발화 (TTS)
  Future<void> playPartnerQuestion() async {
    _isSpeaking = true;
    notifyListeners();

    final pair = currentDialoguePair;
    await _tts.speak(pair.questionFromPartner);

    _isSpeaking = false;
    notifyListeners();
  }

  /// 사용자(전도자) 음성 녹음 시작 (STT)
  Future<void> startVoiceResponse() async {
    _userSpokenText = '';
    _lastQnAResult = null;
    _isListening = true;
    notifyListeners();

    await _stt.startListening();
  }

  /// 녹음 정지 및 즉시 평가
  Future<void> stopVoiceResponse() async {
    _isListening = false;
    await _stt.stopListening();
  }

  void _evaluateCurrentSpoken() {
    if (_userSpokenText.isEmpty) return;

    _lastQnAResult = FollowUpEngine.evaluateAssuranceResponse(
      _currentQnAIndex,
      _userSpokenText,
    );
    notifyListeners();
  }

  /// 다음 확신 질문으로 이동
  void nextQnA() {
    if (_currentQnAIndex + 1 < FollowUpData.assuranceQnAList.length) {
      _currentQnAIndex++;
      _userSpokenText = '';
      _lastQnAResult = null;
    } else {
      // 4문답 완료 -> 5손가락 단계로 전환
      _currentStepIndex = 2;
    }
    notifyListeners();
  }

  void prevQnA() {
    if (_currentQnAIndex > 0) {
      _currentQnAIndex--;
      _userSpokenText = '';
      _lastQnAResult = null;
      notifyListeners();
    }
  }

  /// 5손가락 원리 TTS 설명 듣기
  Future<void> speakSelectedPrinciple() async {
    final p = currentGrowthPrinciple;
    final text = "${p.fingerName} ${p.principleName}. ${p.meaning}. ${p.actionGuide}";
    _isSpeaking = true;
    notifyListeners();

    await _tts.speak(text);

    _isSpeaking = false;
    notifyListeners();
  }
}
