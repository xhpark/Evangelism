import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/section_model.dart';
import '../models/step_item_model.dart';
import '../models/exam_result_model.dart';
import '../data/script_repository.dart';
import '../services/quick_trigger_engine.dart';
import '../services/stt_service.dart';
import '../services/scoring_engine.dart';

class QuickTriggerProvider extends ChangeNotifier {
  final ScriptRepository _repository;
  final STTService _stt = STTService();

  List<StepItem> _deck = [];
  List<Section> _sections = [];
  int _currentIndex = 0;
  TriggerDifficulty _difficulty = TriggerDifficulty.master; // 기본 고급 3단어/1.0초
  TriggerCardState _cardState = TriggerCardState.ready;
  double _remainingSeconds = 1.0;
  Timer? _timer;
  final Stopwatch _reactionStopwatch = Stopwatch();
  bool _onlyTransitions = false;
  List<String> _mistakeIds = [];

  // STT & Dual Scoring 상태
  bool _isListening = false;
  String _spokenText = '';
  double _reactionTimeSeconds = 0.0;
  double _speedScore = 0.0; // 순발력 점수 (0~100)
  double _accuracyScore = 0.0; // 정확성 점수 (0~100)
  ExamResult? _evalResult;
  String? _sttError;
  bool _isScoring = false;

  bool _isDisposed = false;

  QuickTriggerProvider(this._repository) {
    _repository.addListener(_onRepositoryChanged);
  }

  void _onRepositoryChanged() {
    if (_cardState != TriggerCardState.countdown &&
        !_isListening &&
        !_isScoring) {
      refreshFromRepository();
    }
  }

  List<StepItem> get deck => _deck;
  List<Section> get sections => _sections;
  int get currentIndex => _currentIndex;
  StepItem? get currentCard =>
      (_deck.isNotEmpty && _currentIndex < _deck.length)
      ? _deck[_currentIndex]
      : null;
  TriggerDifficulty get difficulty => _difficulty;
  TriggerCardState get cardState => _cardState;
  double get remainingSeconds => _remainingSeconds;
  bool get onlyTransitions => _onlyTransitions;
  List<String> get mistakeIds => _mistakeIds;
  int get totalCards => _deck.length;

  bool get isListening => _isListening;
  String get spokenText => _spokenText;
  double get reactionTimeSeconds => _reactionTimeSeconds;
  double get speedScore => _speedScore;
  double get accuracyScore => _accuracyScore;
  ExamResult? get evalResult => _evalResult;
  bool get isScoring => _isScoring;

  /// 현재 출제 카드 및 난이도(배속) 기준 동적 타임아웃 시간(초)
  double get currentTimeoutSeconds {
    final card = currentCard;
    if (card == null) return _difficulty.durationSeconds;
    return QuickTriggerEngine.getTimeoutForStep(card, _difficulty);
  }

  /// 마이크/음성 인식 실패 사유 (없으면 null)
  String? get sttError => _sttError;

  void clearSttError() {
    _sttError = null;
    notifyListeners();
  }

  Future<void> initDeck({bool onlyTransitions = false}) async {
    _onlyTransitions = onlyTransitions;
    _mistakeIds = await _repository.getMistakeStepIds();
    _sections = await _repository.loadSections();
    final allSteps = _sections.expand((s) => s.steps).toList();

    _deck = QuickTriggerEngine.generateDeck(
      allSteps,
      onlyTransitions: onlyTransitions,
    );
    _currentIndex = 0;
    _cardState = TriggerCardState.ready;
    _remainingSeconds = currentTimeoutSeconds;
    _spokenText = '';
    _speedScore = 0.0;
    _accuracyScore = 0.0;
    _evalResult = null;
    if (_isDisposed) return;
    notifyListeners();
  }

  /// 설정 탭에서 대본이 수정/일괄 반영된 뒤 호출한다.
  /// (덱이 옛 문장 객체를 붙들고 있어 수정 전 대본으로 채점되던 문제를 방지)
  Future<void> refreshFromRepository() async {
    await initDeck(onlyTransitions: _onlyTransitions);
  }

  void setDifficulty(TriggerDifficulty diff) {
    _difficulty = diff;
    if (_cardState == TriggerCardState.ready) {
      _remainingSeconds = currentTimeoutSeconds;
    }
    notifyListeners();
  }

  void toggleTransitionOnly(bool value) {
    initDeck(onlyTransitions: value);
  }

  /// 순발력 테스트 & STT 음성 인식 시작
  Future<void> startTimerAndSTT() async {
    if (_isListening || _isScoring) return;
    _timer?.cancel();
    _spokenText = '';
    _reactionTimeSeconds = 0.0;
    _speedScore = 0.0;
    _accuracyScore = 0.0;
    _evalResult = null;
    _sttError = null;
    _cardState = TriggerCardState.countdown;
    final totalDuration = currentTimeoutSeconds;
    _remainingSeconds = totalDuration;
    _isListening = true;
    notifyListeners();

    _reactionStopwatch.reset();
    _reactionStopwatch.start();

    // STT 실시간 수음 시작
    final started = await _stt.startListening(
      onResult: (text) {
        _spokenText = text;
        _markSpeechOnset();
        notifyListeners();
      },
      onLevel: (level) {
        // 음성 에너지가 감지된 시점이 인식 결과보다 빠르므로 반응 시각으로 더 정확하다.
        if (level > 1.0) _markSpeechOnset();
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
      _cardState = TriggerCardState.ready;
      _timer?.cancel();
      _reactionStopwatch.stop();
      notifyListeners();
      return;
    }

    const tickMs = 100;
    final totalTicks = (totalDuration * 1000 / tickMs).round();
    int currentTick = 0;

    _timer = Timer.periodic(const Duration(milliseconds: tickMs), (t) {
      currentTick++;
      _remainingSeconds =
          (totalDuration - (currentTick * tickMs / 1000)).clamp(
            0.0,
            totalDuration,
          );

      if (currentTick >= totalTicks) {
        _timer?.cancel();
        _remainingSeconds = 0.0;
        // 타이머가 종료되어도 사용자가 말하고 있으면 자연스럽게 수음 유지
        notifyListeners();
      } else {
        notifyListeners();
      }
    });
  }

  /// 발화 시작 시각 기록 (최초 1회만)
  void _markSpeechOnset() {
    if (_reactionTimeSeconds == 0.0 && _reactionStopwatch.isRunning) {
      _reactionTimeSeconds = _reactionStopwatch.elapsedMilliseconds / 1000.0;
    }
  }

  /// 탭 이동/백그라운드 전환 등으로 수음을 강제 중단 (채점하지 않음)
  Future<void> abortListening() async {
    _timer?.cancel();
    _reactionStopwatch.stop();
    _isListening = false;
    await _stt.cancel();
    _cardState = TriggerCardState.ready;
    _remainingSeconds = currentTimeoutSeconds;
    notifyListeners();
  }

  /// 수음 종료 및 순발력 점수 + 정확성 점수 듀얼 채점
  Future<void> finishAndScore() async {
    if (_isScoring ||
        (!_isListening && _cardState == TriggerCardState.revealed)) {
      return;
    }
    _timer?.cancel();
    _reactionStopwatch.stop();
    _isListening = false;
    await _stt.stopListening();

    final card = currentCard;
    if (card == null) return;

    // 1. 순발력 점수 산출 (시간 내 반응 속도 기준)
    final limit = currentTimeoutSeconds;
    final reaction = (_reactionTimeSeconds > 0.0)
        ? _reactionTimeSeconds
        : (_reactionStopwatch.elapsedMilliseconds / 1000.0);
    _reactionTimeSeconds = reaction;

    if (reaction <= limit) {
      // 제한 시간 내 발화 시작 시 70~100점
      _speedScore = (((limit - reaction) / limit) * 30.0 + 70.0).clamp(
        70.0,
        100.0,
      );
    } else {
      // 제한 시간 초과 시 30~65점
      final overRatio = ((reaction - limit) / limit).clamp(0.0, 1.0);
      _speedScore = (65.0 - overRatio * 35.0).clamp(20.0, 65.0);
    }

    _isScoring = true;
    notifyListeners();

    // 2. 정확성 점수 산출 (원문 대조 어절 정렬 Diff & 키워드 가중치)
    try {
      final result = await ScoringEngine.calculateScoreAsync(
        examId: 'trigger_${card.stepId}',
        title: card.name,
        originalText: card.effectiveScript,
        spokenText: _spokenText,
        keywords: card.keywords,
      );
      _accuracyScore = result.totalScore;
      _evalResult = result;
      if (_accuracyScore < 80.0) {
        await _repository.addMistake(card.stepId);
      } else {
        await _repository.removeMistake(card.stepId);
      }
      _mistakeIds = await _repository.getMistakeStepIds();
      _cardState = TriggerCardState.revealed;
    } finally {
      _isScoring = false;
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  /// 다음 카드로 넘기기
  Future<void> nextCard() async {
    _timer?.cancel();
    _reactionStopwatch.stop();
    await _stt.stopListening();
    _isListening = false;
    _spokenText = '';
    _speedScore = 0.0;
    _accuracyScore = 0.0;
    _evalResult = null;

    if (_currentIndex + 1 < _deck.length) {
      _currentIndex++;
      _cardState = TriggerCardState.ready;
      _remainingSeconds = currentTimeoutSeconds;
    } else {
      // 전체 카드 완주 후 재셔플
      await initDeck(onlyTransitions: _onlyTransitions);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _repository.removeListener(_onRepositoryChanged);
    _timer?.cancel();
    _reactionStopwatch.stop();
    _stt.cancel();
    super.dispose();
  }
}
