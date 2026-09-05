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
  String? _selectedStepId;
  bool _blindMode = false;
  double _speedRate = 1.0;
  PlayMode _playMode = PlayMode.sectionRepeat; // 기본: 현재 챕터 무한 반복
  bool _isLoading = true;

  bool _isContinuousPlaying = false;
  int _playbackSessionId = 0;

  StudyProvider(this._repository) {
    _repository.addListener(_onRepositoryChanged);
    _init();
  }

  void _onRepositoryChanged() {
    refresh();
  }

  List<Section> get sections => _sections;
  int get selectedSectionIndex => _selectedSectionIndex;
  Section? get currentSection =>
      _sections.isNotEmpty ? _sections[_selectedSectionIndex] : null;
  String? get activeStepId => _activeStepId;
  String? get selectedStepId => _selectedStepId;
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

  Future<void> reloadVoices() async {
    await _ttsService.refreshVoices();
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

    if (_sections.isNotEmpty && _sections[0].steps.isNotEmpty) {
      _selectedStepId = _sections[0].steps[0].stepId;
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectSection(int index) {
    if (index >= 0 && index < _sections.length) {
      stopAudio();
      _selectedSectionIndex = index;
      _activeStepId = null;
      _selectedStepId = _sections[index].steps.isNotEmpty
          ? _sections[index].steps.first.stepId
          : null;
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
            if (_playMode == PlayMode.singleRepeat) {
              playContinuous(fromIndex: curIdx);
            } else if (curIdx + 1 < steps.length) {
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
            initialText: (remaining.isNotEmpty && remaining.length > 1)
                ? remaining
                : null,
          );
        }
      }
    }
  }

  /// 특정 스텝 단일/반복 재생
  Future<void> playStep(StepItem step, {String? initialText}) async {
    _selectedStepId = step.stepId;

    if (_playMode == PlayMode.singleRepeat) {
      // 선택문장 무한 반복 모드
      // 이미 해당 선택 문장이 반복 재생 중인 경우 정지 토글
      if (_isContinuousPlaying && _activeStepId == step.stepId) {
        await stopAudio();
        return;
      }

      final steps = currentSection?.steps ?? [];
      final curIdx = steps.indexWhere((s) => s.stepId == step.stepId);
      await playContinuous(
        fromIndex: curIdx >= 0 ? curIdx : 0,
        initialText: initialText,
      );
      return;
    }

    // 다른 모드일 때는 해당 문장 1회 듣기
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
  Future<void> playContinuous({int? fromIndex, String? initialText}) async {
    if (_sections.isEmpty) return;

    final steps = currentSection?.steps ?? [];
    int startIndex;
    if (fromIndex != null) {
      startIndex = fromIndex;
    } else if (_selectedStepId != null) {
      final idx = steps.indexWhere((s) => s.stepId == _selectedStepId);
      startIndex = idx >= 0 ? idx : 0;
    } else if (_activeStepId != null) {
      final idx = steps.indexWhere((s) => s.stepId == _activeStepId);
      startIndex = idx >= 0 ? idx : 0;
    } else {
      startIndex = 0;
    }

    _isContinuousPlaying = true;
    _playbackSessionId++;
    final currentSession = _playbackSessionId;

    await DeviceHelperService.enableKeepScreenOn();

    // 1. [선택문장 무한 반복 모드]
    if (_playMode == PlayMode.singleRepeat) {
      final curStep = (steps.isNotEmpty && startIndex >= 0 && startIndex < steps.length)
          ? steps[startIndex]
          : (steps.firstWhere(
              (s) => s.stepId == _selectedStepId || s.stepId == _activeStepId,
              orElse: () => steps.first,
            ));

      _selectedStepId = curStep.stepId;
      bool isFirst = true;
      while (_isContinuousPlaying &&
          _playbackSessionId == currentSession &&
          _playMode == PlayMode.singleRepeat) {
        _activeStepId = curStep.stepId;
        notifyListeners();

        final text = (isFirst && initialText != null)
            ? initialText
            : curStep.effectiveScript;
        isFirst = false;

        await _ttsService.speak(text, stepId: curStep.stepId);
        if (!_isContinuousPlaying || _playbackSessionId != currentSession) {
          break;
        }
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    // 2. [현재 챕터 무한 반복 모드]
    else if (_playMode == PlayMode.sectionRepeat) {
      int currentStartIndex = startIndex;
      String? currentInitialText = initialText;

      while (_isContinuousPlaying &&
          _playbackSessionId == currentSession &&
          _playMode == PlayMode.sectionRepeat) {
        for (var i = currentStartIndex; i < steps.length; i++) {
          if (!_isContinuousPlaying || _playbackSessionId != currentSession) {
            break;
          }
          final s = steps[i];
          _activeStepId = s.stepId;
          _selectedStepId = s.stepId;
          notifyListeners();

          final text = (i == currentStartIndex && currentInitialText != null)
              ? currentInitialText
              : s.effectiveScript;

          await _ttsService.speak(text, stepId: s.stepId);
          if (!_isContinuousPlaying || _playbackSessionId != currentSession) {
            break;
          }
          await Future.delayed(const Duration(milliseconds: 200));
        }
        currentStartIndex = 0;
        currentInitialText = null;
      }
    }
    // 3. [현재 챕터 1회 재생 모드]
    else if (_playMode == PlayMode.sectionPlay) {
      for (var i = startIndex; i < steps.length; i++) {
        if (!_isContinuousPlaying || _playbackSessionId != currentSession) {
          break;
        }
        final s = steps[i];
        _activeStepId = s.stepId;
        _selectedStepId = s.stepId;
        notifyListeners();

        final text = (i == startIndex && initialText != null)
            ? initialText
            : s.effectiveScript;
        await _ttsService.speak(text, stepId: s.stepId);
        if (!_isContinuousPlaying || _playbackSessionId != currentSession) {
          break;
        }
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    // 4. [전체 전문(1~8) 완주 재생 모드]
    else if (_playMode == PlayMode.allSequentialPlay) {
      // 시작 위치는 '재생을 시작한 그 챕터'에만 적용한다.
      // (2026-08-29: 루프 안에서 _selectedSectionIndex를 먼저 대입하는 바람에
      //  모든 챕터가 fromIndex부터 시작해 앞 문장들이 통째로 건너뛰던 문제를 수정)
      final startSectionIndex = _selectedSectionIndex;

      for (
        var secIdx = startSectionIndex;
        secIdx < _sections.length;
        secIdx++
      ) {
        if (!_isContinuousPlaying || _playbackSessionId != currentSession) {
          break;
        }
        _selectedSectionIndex = secIdx;
        notifyListeners();

        final secSteps = _sections[secIdx].steps;
        final isStartSection = (secIdx == startSectionIndex);
        final startIdx = isStartSection ? startIndex.clamp(0, secSteps.length) : 0;

        for (var stepIdx = startIdx; stepIdx < secSteps.length; stepIdx++) {
          if (!_isContinuousPlaying || _playbackSessionId != currentSession) {
            break;
          }
          final s = secSteps[stepIdx];
          _activeStepId = s.stepId;
          _selectedStepId = s.stepId;
          notifyListeners();

          final text =
              (isStartSection && stepIdx == startIdx && initialText != null)
              ? initialText
              : s.effectiveScript;

          await _ttsService.speak(text, stepId: s.stepId);
          if (!_isContinuousPlaying || _playbackSessionId != currentSession) {
            break;
          }
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

  bool _isDisposed = false;

  /// 데이터 새로고침
  Future<void> refresh() async {
    final loadedSections = await _repository.loadSections();
    if (_isDisposed) return;
    _sections = loadedSections;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _repository.removeListener(_onRepositoryChanged);
    super.dispose();
  }
}
