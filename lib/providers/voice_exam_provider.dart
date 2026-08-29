import 'package:flutter/foundation.dart';
import '../models/exam_result_model.dart';
import '../data/script_repository.dart';
import '../services/stt_service.dart';
import '../services/scoring_engine.dart';
import '../services/random_exam_engine.dart';
import '../services/device_helper_service.dart';
import '../services/quick_trigger_engine.dart';

class VoiceExamProvider extends ChangeNotifier {
  final ScriptRepository _repository;
  final STTService _stt = STTService();
  final RandomExamEngine _examEngine = RandomExamEngine();

  ExamMode _selectedMode = ExamMode.transitionChain;
  TriggerDifficulty _difficulty = TriggerDifficulty.master; // 기본 3단어 (고급/실전)
  ExamQuestion? _currentQuestion;
  bool _isListening = false;
  String _liveSpokenText = '';
  double _soundLevel = 0.0;
  ExamResult? _lastResult;
  List<ExamResult> _history = [];
  bool _isLoading = false;

  VoiceExamProvider(this._repository) {
    _init();
  }

  ExamMode get selectedMode => _selectedMode;
  TriggerDifficulty get difficulty => _difficulty;
  ExamQuestion? get currentQuestion => _currentQuestion;
  bool get isListening => _isListening;
  String get liveSpokenText => _liveSpokenText;
  double get soundLevel => _soundLevel;
  ExamResult? get lastResult => _lastResult;
  List<ExamResult> get history => _history;
  bool get isLoading => _isLoading;

  void setDifficulty(TriggerDifficulty diff) {
    _difficulty = diff;
    notifyListeners();
  }

  Future<void> _init() async {
    await _stt.initialize();
    _history = await _repository.getExamHistory();

    _stt.onResultChanged = (text) {
      _liveSpokenText = text;
      notifyListeners();
    };

    _stt.onSoundLevelChanged = (level) {
      _soundLevel = level;
      notifyListeners();
    };

    _stt.onListeningStopped = () {
      _isListening = false;
      notifyListeners();
    };

    await generateNewQuestion();
  }

  Future<void> setExamMode(ExamMode mode) async {
    _selectedMode = mode;
    _lastResult = null;
    _liveSpokenText = '';
    notifyListeners();
    await generateNewQuestion();
  }

  /// 시험 문제 출제 생성
  Future<void> generateNewQuestion() async {
    _isLoading = true;
    _lastResult = null;
    _liveSpokenText = '';
    notifyListeners();

    final sections = await _repository.loadSections();
    _currentQuestion = _examEngine.generateQuestion(_selectedMode, sections);

    _isLoading = false;
    notifyListeners();
  }

  /// 시험 녹음 시작 (STT)
  Future<void> startExamRecording() async {
    if (_currentQuestion == null) await generateNewQuestion();

    _liveSpokenText = '';
    _lastResult = null;
    _isListening = true;
    notifyListeners();

    await DeviceHelperService.enableKeepScreenOn();
    await _stt.startListening(clearBuffer: true);
  }

  /// 시험 녹음 정지 및 자동 채점
  Future<void> finishAndScoreExam() async {
    _isListening = false;
    await _stt.stopListening();
    await DeviceHelperService.disableKeepScreenOn();

    if (_currentQuestion == null) return;

    List<ExamAreaScore>? areaBreakdown;
    if (_selectedMode == ExamMode.fullSequential) {
      areaBreakdown = RandomExamEngine.calculate5AreaBreakdown(
        _currentQuestion!.originalText,
        _liveSpokenText,
      );
    }

    final result = ScoringEngine.calculateScore(
      examId: 'exam_${DateTime.now().millisecondsSinceEpoch}',
      title: _currentQuestion!.title,
      originalText: _currentQuestion!.originalText,
      spokenText: _liveSpokenText,
      keywords: _currentQuestion!.keywords,
      areaScores: areaBreakdown,
    );

    _lastResult = result;
    await _repository.saveExamResult(result);
    _history = await _repository.getExamHistory();

    notifyListeners();
  }

  /// 녹음 취소
  Future<void> cancelExam() async {
    _isListening = false;
    await _stt.cancel();
    await DeviceHelperService.disableKeepScreenOn();
    _liveSpokenText = '';
    _lastResult = null;
    notifyListeners();
  }
}
