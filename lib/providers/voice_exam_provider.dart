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
  bool _isScoring = false;
  String? _sttError;

  bool _isDisposed = false;

  VoiceExamProvider(this._repository) {
    _repository.addListener(_onRepositoryChanged);
    _init();
  }

  void _onRepositoryChanged() {
    if (!_isListening && !_isScoring) {
      generateNewQuestion();
    }
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
  bool get isScoring => _isScoring;

  /// 마이크/음성 인식 실패 사유 (없으면 null)
  String? get sttError => _sttError;

  void clearSttError() {
    _sttError = null;
    notifyListeners();
  }

  void setDifficulty(TriggerDifficulty diff) {
    _difficulty = diff;
    notifyListeners();
  }

  Future<void> _init() async {
    _history = await _repository.getExamHistory();
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
    if (_isDisposed) return;
    _isLoading = true;
    _lastResult = null;
    _liveSpokenText = '';
    notifyListeners();

    final sections = await _repository.loadSections();
    if (_isDisposed) return;
    _currentQuestion = _examEngine.generateQuestion(_selectedMode, sections);

    _isLoading = false;
    notifyListeners();
  }

  /// 시험 녹음 시작 (STT)
  ///
  /// 실전 시험은 한 문항이 길기 때문에 [keepAlive]로 수음을 유지한다.
  /// 숨을 고르느라 4초 이상 쉬어 인식기가 멈춰도 지금까지의 인식 결과에 이어서 자동 재개된다.
  Future<void> startExamRecording() async {
    if (_isListening || _isScoring) return;
    if (_currentQuestion == null) await generateNewQuestion();

    _liveSpokenText = '';
    _lastResult = null;
    _sttError = null;
    _isListening = true;
    notifyListeners();

    await DeviceHelperService.enableKeepScreenOn();

    final started = await _stt.startListening(
      keepAlive: true,
      onResult: (text) {
        _liveSpokenText = text;
        notifyListeners();
      },
      onLevel: (level) {
        _soundLevel = level;
        notifyListeners();
      },
      onStopped: () {
        _isListening = false;
        notifyListeners();
      },
      onError: (message) {
        _sttError = message;
        _isListening = false;
        notifyListeners();
      },
    );

    if (!started) {
      _isListening = false;
      await DeviceHelperService.disableKeepScreenOn();
      notifyListeners();
    }
  }

  /// 시험 녹음 정지 및 자동 채점
  Future<void> finishAndScoreExam() async {
    if (_isScoring || !_isListening) return;
    _isListening = false;
    await _stt.stopListening();
    await DeviceHelperService.disableKeepScreenOn();

    if (_currentQuestion == null) return;

    if (_liveSpokenText.trim().isEmpty) {
      _sttError = '인식된 음성이 없어 채점하지 않았습니다. 마이크 권한과 주변 소음을 확인한 뒤 다시 시도해 주세요.';
      notifyListeners();
      return;
    }

    _isScoring = true;
    notifyListeners();

    List<ExamAreaScore>? areaBreakdown;
    if (_selectedMode == ExamMode.fullSequential) {
      areaBreakdown = RandomExamEngine.calculate5AreaBreakdown(
        _currentQuestion!.originalText,
        _liveSpokenText,
      );
    }

    // 전체 완주 시험은 지문이 7,000자를 넘어 편집거리 계산이 무겁다.
    // 별도 아이솔레이트에서 채점해 화면이 멈추지 않도록 한다.
    try {
      final result = await ScoringEngine.calculateScoreAsync(
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
    } finally {
      _isScoring = false;
      notifyListeners();
    }
  }

  /// 녹음 취소
  Future<void> cancelExam() async {
    _isListening = false;
    _sttError = null;
    await _stt.cancel();
    await DeviceHelperService.disableKeepScreenOn();
    _liveSpokenText = '';
    _lastResult = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _repository.removeListener(_onRepositoryChanged);
    _stt.cancel();
    super.dispose();
  }
}
