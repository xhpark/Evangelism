import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/section_model.dart';
import '../models/step_item_model.dart';
import '../data/script_repository.dart';
import '../services/tts_service.dart';
import '../services/device_helper_service.dart';

class StudyProvider extends ChangeNotifier {
  final ScriptRepository _repository;
  final TTSService _ttsService = TTSService();

  List<Section> _sections = [];
  int _selectedSectionIndex = 0;
  String? _activeStepId;
  bool _blindMode = false;
  double _speedRate = 1.0;
  PlayMode _playMode = PlayMode.sectionRepeat; // 기본: 현재 챕터 무한 반복
  bool _isLoading = true;

  bool _isContinuousPlaying = false;
  int _playbackSessionId = 0;

  StudyProvider(this._repository) {
    _init();
  }

  List<Section> get sections => _sections;
  int get selectedSectionIndex => _selectedSectionIndex;
  Section? get currentSection =>
      _sections.isNotEmpty ? _sections[_selectedSectionIndex] : null;
  String? get activeStepId => _activeStepId;
  bool get blindMode => _blindMode;
  double get speedRate => _speedRate;
  PlayMode get playMode => _playMode;
  bool get isPlaying => _ttsService.isPlaying || _isContinuousPlaying;
  bool get isLoading => _isLoading;

  List<TTSVoiceInfo> get availableVoices => _ttsService.availableVoices;
  String get selectedVoiceName => _ttsService.selectedVoiceName;
  double get pitch => _ttsService.pitch;

  Future<void> setTtsVoice(TTSVoiceInfo voice) async {
    await _ttsService.setVoice(voice);
    notifyListeners();
  }

  Future<void> setTtsPitch(double pitchVal) async {
    await _ttsService.setPitch(pitchVal);
    notifyListeners();
  }

  Future<void> previewTtsVoice() async {
    await _ttsService.previewVoice();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    await _ttsService.initialize();
    _sections = await _repository.loadSections();

    _ttsService.onStepStarted = (stepId) {
      _activeStepId = stepId;
      notifyListeners();
    };

    _ttsService.onStepCompleted = (stepId) {
      notifyListeners();
    };

    _isLoading = false;
    notifyListeners();
  }

  void selectSection(int index) {
    if (index >= 0 && index < _sections.length) {
      stopAudio();
      _selectedSectionIndex = index;
      _activeStepId = null;
      notifyListeners();
    }
  }

  /// 특정 문장 수정 및 즉시 저장/반영
  Future<void> updateStepScript(String stepId, String newScript) async {
    await _repository.updateStepScript(stepId, newScript);
    _sections = await _repository.loadSections();
    notifyListeners();
  }

  void toggleBlindMode() {
    _blindMode = !_blindMode;
    notifyListeners();
  }

  /// 재생 모드 변경
  void setPlayMode(PlayMode mode) {
    _playMode = mode;
    _ttsService.setPlayMode(mode);
    notifyListeners();

    if (_isContinuousPlaying && _activeStepId != null) {
      final steps = currentSection?.steps ?? [];
      final curIdx = steps.indexWhere((s) => s.stepId == _activeStepId);
      if (curIdx != -1) {
        _playbackSessionId++;
        _ttsService.stop();
        playContinuous(fromIndex: curIdx);
      }
    }
  }

  /// 배속 변경
  Future<void> setSpeedRate(double rate) async {
    if (_speedRate == rate) return;
    _speedRate = rate;
    await _ttsService.setSpeedRate(rate);
    notifyListeners();

    if (_activeStepId != null) {
      final remaining = _ttsService.getRemainingText();
      final currentStepId = _activeStepId;
      final isContinuous = _isContinuousPlaying;

      _playbackSessionId++;
      await _ttsService.stop();
      await Future.delayed(const Duration(milliseconds: 60));

      if (isContinuous) {
        final steps = currentSection?.steps ?? [];
        final curIdx = steps.indexWhere((s) => s.stepId == currentStepId);
        if (curIdx != -1) {
          if (remaining.isNotEmpty && remaining.length > 1) {
            playContinuous(fromIndex: curIdx, initialText: remaining);
          } else {
            if (curIdx + 1 < steps.length) {
              playContinuous(fromIndex: curIdx + 1);
            }
          }
        }
      } else {
        final curStep = currentSection?.steps.firstWhere(
          (s) => s.stepId == currentStepId,
          orElse: () => currentSection!.steps.first,
        );
        if (curStep != null) {
          playStep(
            curStep,
            initialText: (remaining.isNotEmpty && remaining.length > 1) ? remaining : null,
          );
        }
      }
    }
  }

  /// 특정 스텝 단일 재생
  Future<void> playStep(StepItem step, {String? initialText}) async {
    _isContinuousPlaying = false;
    _playbackSessionId++;
    final currentSession = _playbackSessionId;

    _activeStepId = step.stepId;
    notifyListeners();

    await DeviceHelperService.enableKeepScreenOn();
    final textToSpeak = initialText ?? step.effectiveScript;
    await _ttsService.speak(textToSpeak, stepId: step.stepId);

    if (_playbackSessionId == currentSession) {
      _activeStepId = null;
      await DeviceHelperService.disableKeepScreenOn();
      notifyListeners();
    }
  }

  /// 4대 재생 모드 실행
  Future<void> playContinuous({int fromIndex = 0, String? initialText}) async {
    if (_sections.isEmpty) return;

    _isContinuousPlaying = true;
    _playbackSessionId++;
    final currentSession = _playbackSessionId;

    await DeviceHelperService.enableKeepScreenOn();

    // 1. [1문장 무한 반복 모드]
    if (_playMode == PlayMode.singleRepeat) {
      final steps = currentSection?.steps ?? [];
      final curStep = (steps.isNotEmpty && fromIndex < steps.length)
          ? steps[fromIndex]
          : (steps.firstWhere(
              (s) => s.stepId == _activeStepId,
              orElse: () => steps.first,
            ));

      bool isFirst = true;
      while (_isContinuousPlaying &&
          _playbackSessionId == currentSession &&
          _playMode == PlayMode.singleRepeat) {
        _activeStepId = curStep.stepId;
        notifyListeners();

        final text = (isFirst && initialText != null) ? initialText : curStep.effectiveScript;
        isFirst = false;

        await _ttsService.speak(text, stepId: curStep.stepId);
        if (!_isContinuousPlaying || _playbackSessionId != currentSession) break;
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    // 2. [현재 챕터 무한 반복 모드]
    else if (_playMode == PlayMode.sectionRepeat) {
      final steps = currentSection?.steps ?? [];
      int currentStartIndex = fromIndex;
      String? currentInitialText = initialText;

      while (_isContinuousPlaying &&
          _playbackSessionId == currentSession &&
          _playMode == PlayMode.sectionRepeat) {
        for (var i = currentStartIndex; i < steps.length; i++) {
          if (!_isContinuousPlaying || _playbackSessionId != currentSession) break;
          final s = steps[i];
          _activeStepId = s.stepId;
          notifyListeners();

          final text = (i == currentStartIndex && currentInitialText != null)
              ? currentInitialText
              : s.effectiveScript;

          await _ttsService.speak(text, stepId: s.stepId);
          if (!_isContinuousPlaying || _playbackSessionId != currentSession) break;
          await Future.delayed(const Duration(milliseconds: 200));
        }
        currentStartIndex = 0;
        currentInitialText = null;
      }
    }
    // 3. [현재 챕터 1회 재생 모드]
    else if (_playMode == PlayMode.sectionPlay) {
      final steps = currentSection?.steps ?? [];
      for (var i = fromIndex; i < steps.length; i++) {
        if (!_isContinuousPlaying || _playbackSessionId != currentSession) break;
        final s = steps[i];
        _activeStepId = s.stepId;
        notifyListeners();

        final text = (i == fromIndex && initialText != null) ? initialText : s.effectiveScript;
        await _ttsService.speak(text, stepId: s.stepId);
        if (!_isContinuousPlaying || _playbackSessionId != currentSession) break;
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    // 4. [전체 전문(1~8) 완주 재생 모드]
    else if (_playMode == PlayMode.allSequentialPlay) {
      for (var secIdx = _selectedSectionIndex; secIdx < _sections.length; secIdx++) {
        if (!_isContinuousPlaying || _playbackSessionId != currentSession) break;
        _selectedSectionIndex = secIdx;
        notifyListeners();

        final steps = _sections[secIdx].steps;
        final startIdx = (secIdx == _selectedSectionIndex) ? fromIndex : 0;

        for (var stepIdx = startIdx; stepIdx < steps.length; stepIdx++) {
          if (!_isContinuousPlaying || _playbackSessionId != currentSession) break;
          final s = steps[stepIdx];
          _activeStepId = s.stepId;
          notifyListeners();

          final text = (secIdx == _selectedSectionIndex && stepIdx == fromIndex && initialText != null)
              ? initialText
              : s.effectiveScript;

          await _ttsService.speak(text, stepId: s.stepId);
          if (!_isContinuousPlaying || _playbackSessionId != currentSession) break;
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
    }

    if (_playbackSessionId == currentSession) {
      _isContinuousPlaying = false;
      _activeStepId = null;
      await DeviceHelperService.disableKeepScreenOn();
      notifyListeners();
    }
  }

  Future<void> stopAudio() async {
    _isContinuousPlaying = false;
    _playbackSessionId++;
    await _ttsService.stop();
    await DeviceHelperService.disableKeepScreenOn();
    _activeStepId = null;
    notifyListeners();
  }

  /// 데이터 새로고침
  Future<void> refresh() async {
    _sections = await _repository.loadSections();
    notifyListeners();
  }
}
