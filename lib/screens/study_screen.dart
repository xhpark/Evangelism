import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/study_provider.dart';
import '../widgets/audio_control_bar.dart';
import '../widgets/sentence_card.dart';
import '../widgets/hand_outline_widget.dart';
import '../theme/app_theme.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _itemKeys = {};
  String? _lastActiveStepId;

  Timer? _progressiveScrollTimer;

  @override
  void dispose() {
    _progressiveScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  GlobalKey _getKeyForStep(String stepId) {
    return _itemKeys.putIfAbsent(stepId, () => GlobalKey());
  }

  void _scrollToActiveStep(StudyProvider study) {
    if (study.activeStepId == null || study.activeStepId == _lastActiveStepId) {
      return;
    }
    _lastActiveStepId = study.activeStepId;
    _progressiveScrollTimer?.cancel();

    final currentSection = study.currentSection;
    if (currentSection == null || currentSection.steps.isEmpty) return;

    final activeIndex = currentSection.steps
        .indexWhere((step) => step.stepId == study.activeStepId);

    if (activeIndex != -1 && _scrollController.hasClients) {
      final activeStep = currentSection.steps[activeIndex];
      final isLongCard = activeStep.effectiveScript.length > 180;

      // 1. 첫 번째 문장(0번 인덱스)으로 돌아온 경우: 리스트 최상단(0.0)으로 확실하게 스크롤 이동
      if (activeIndex == 0) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic,
        );
      } else {
        // 2. GlobalKey의 Context가 유효한 경우: 긴 카드는 상단(0.08), 짧은 카드는 중앙(0.5)으로 정렬
        final key = _itemKeys[study.activeStepId];
        if (key != null && key.currentContext != null) {
          Scrollable.ensureVisible(
            key.currentContext!,
            alignment: isLongCard ? 0.08 : 0.5,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
          );
        } else {
          // 3. 화면 밖으로 언마운트된 경우: 인덱스 기반으로 대략적인 위치로 이동
          const estimatedCardHeight = 160.0;
          final viewportHeight = _scrollController.position.viewportDimension;
          final targetOffset = (activeIndex * estimatedCardHeight - (viewportHeight * (isLongCard ? 0.1 : 0.4)))
              .clamp(0.0, _scrollController.position.maxScrollExtent);

          _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
          );
        }
      }

      // 3. 긴 카드의 경우 (예화/기도 등): 발화 중간(약 50% 시점)에 카드의 하단부로 자연스럽게 스크롤 추적
      if (isLongCard && study.isPlaying) {
        final durationSeconds = (activeStep.effectiveScript.length / (9.0 * study.speedRate)).clamp(4.0, 35.0);
        final delayMs = (durationSeconds * 450).round(); // 전체 발화 시간의 약 45% 시점

        _progressiveScrollTimer = Timer(Duration(milliseconds: delayMs), () {
          if (!mounted || study.activeStepId != activeStep.stepId || !study.isPlaying) return;
          final key = _itemKeys[activeStep.stepId];
          if (key != null && key.currentContext != null) {
            Scrollable.ensureVisible(
              key.currentContext!,
              alignment: 0.85,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOutCubic,
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final study = context.watch<StudyProvider>();

    if (study.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 활성 문장이 변경되거나 카드를 탭했을 때 화면 중앙으로 자동 정렬
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveStep(study);
    });

    final currentSection = study.currentSection;

    return Scaffold(
      appBar: AppBar(
        title: const Text("전도폭발 JUST EE 전문 학습"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "데이터 새로고침",
            onPressed: () => study.refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. 상단 챕터 선택 탭바 (고대비 & 모든 글자가 선명하게 보이는 디자인)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: List.generate(study.sections.length, (idx) {
                  final sec = study.sections[idx];
                  final isSelected = (idx == study.selectedSectionIndex);

                  // 챕터 이름 가공 (예: "1. 서론", "2.1 은혜", "2.2 인간" 등)
                  final parts = sec.title.split(' ');
                  final labelText = parts.length >= 2
                      ? "${parts[0]} ${parts[1]}"
                      : sec.title;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        _lastActiveStepId = null;
                        study.selectSection(idx);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryBlue
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryBlue
                                : const Color(0xFFCBD5E1),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          labelText,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // 2. 5손가락 연상 가이드 (복음 대지인 경우 노출)
          if (currentSection != null && currentSection.fingerIndex != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: HandOutlineWidget(
                selectedIndex: currentSection.fingerIndex!,
                onFingerSelected: (fingerIdx) {
                  _lastActiveStepId = null;
                  final targetIdx = study.sections.indexWhere((s) => s.fingerIndex == fingerIdx);
                  if (targetIdx != -1) study.selectSection(targetIdx);
                },
              ),
            ),

          // 3. 섹션 타이틀 헤더
          if (currentSection != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      currentSection.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                  ),
                  Text(
                    "총 ${currentSection.steps.length}개 문장",
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),

          // 4. 문장 리스트 (가상화 언마운트 방지를 위해 cacheExtent 부여)
          Expanded(
            child: (currentSection == null || currentSection.steps.isEmpty)
                ? const Center(child: Text("표시할 문장이 없습니다."))
                : ListView.builder(
                    controller: _scrollController,
                    cacheExtent: 2500.0, // 전체 문장 카드를 메모리에 유지하여 스크롤 추적 보장
                    padding: const EdgeInsets.only(bottom: 24, top: 4),
                    itemCount: currentSection.steps.length,
                    itemBuilder: (ctx, idx) {
                      final step = currentSection.steps[idx];
                      final isFocused = (step.stepId == study.activeStepId);
                      final itemKey = _getKeyForStep(step.stepId);

                      return KeyedSubtree(
                        key: itemKey,
                        child: SentenceCard(
                          step: step,
                          isActive: isFocused,
                          isBlindMode: study.blindMode,
                          onPlay: () {
                            _lastActiveStepId = null;
                            study.playStep(step);
                          },
                          onEdit: (newText) async {
                            await study.updateStepScript(step.stepId, newText);
                          },
                        ),
                      );
                    },
                  ),
          ),

          // 5. 하단 오디오 컨트롤 바
          const AudioControlBar(),
        ],
      ),
    );
  }
}
