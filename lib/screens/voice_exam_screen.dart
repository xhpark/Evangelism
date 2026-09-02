import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_exam_provider.dart';
import '../services/random_exam_engine.dart';
import '../services/quick_trigger_engine.dart';
import '../widgets/speech_level_indicator.dart';
import '../widgets/diff_report_widget.dart';
import '../theme/app_theme.dart';

class VoiceExamScreen extends StatefulWidget {
  const VoiceExamScreen({super.key});

  @override
  State<VoiceExamScreen> createState() => _VoiceExamScreenState();
}

class _VoiceExamScreenState extends State<VoiceExamScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🎙️ 실전 STT 음성 암송 시험"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentGold,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: "🎯 모의 시험 응시"),
            Tab(text: "📜 시험 성적 이력"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_ExamTakingTabView(), _ExamHistoryTabView()],
      ),
    );
  }
}

class _ExamTakingTabView extends StatelessWidget {
  const _ExamTakingTabView();

  @override
  Widget build(BuildContext context) {
    final exam = context.watch<VoiceExamProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 시험 출제 모드 선택
          const Text(
            "실전 시험 모드 선택:",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ExamMode.values.map((mode) {
                final isSelected = (exam.selectedMode == mode);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Text(
                      mode.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: mode == ExamMode.randomMix
                        ? AppTheme.accentGold
                        : AppTheme.primaryBlue,
                    onSelected: (val) {
                      if (val) exam.setExamMode(mode);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // 2. 출제 문제 카드 (시작 문두 & 미션 지침 강조)
          if (exam.currentQuestion == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.casino,
                    size: 40,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    exam.selectedMode.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    exam.selectedMode.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => exam.generateNewQuestion(),
                    icon: const Icon(Icons.play_circle_filled),
                    label: const Text("새 문제 출제하기"),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          exam.currentQuestion!.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        tooltip: "다른 문제 다시 뽑기",
                        onPressed: () => exam.generateNewQuestion(),
                      ),
                    ],
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Text(
                          "문두 힌트:",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildLevelChip(
                          context,
                          exam,
                          TriggerDifficulty.beginner,
                          "초급 (5단어)",
                        ),
                        const SizedBox(width: 4),
                        _buildLevelChip(
                          context,
                          exam,
                          TriggerDifficulty.intermediate,
                          "중급 (4단어)",
                        ),
                        const SizedBox(width: 4),
                        _buildLevelChip(
                          context,
                          exam,
                          TriggerDifficulty.master,
                          "고급 (3단어)",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 시작 문두 제시 박스
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF), // light blue
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.record_voice_over,
                                    size: 15,
                                    color: AppTheme.primaryBlue,
                                  ),
                                  SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      "시작 문두 (이어서 암송 시작):",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "${QuickTriggerEngine.getWordCountForDifficulty(exam.difficulty)}단어 힌트",
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "\"${exam.currentQuestion!.getTriggerPrompt(exam.difficulty)}\"",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 미션 지침 박스
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB), // light amber
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("📌", style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            exam.currentQuestion!.instruction,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF92400E),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // 마이크/음성 인식 오류 안내
          if (exam.sttError != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.mic_off_outlined,
                    size: 18,
                    color: AppTheme.accentRed,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      exam.sttError!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF991B1B),
                        height: 1.4,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: exam.clearSttError,
                    tooltip: "닫기",
                  ),
                ],
              ),
            ),

          // 채점 진행 표시 (전체 완주 시험은 지문이 길어 수 초가 걸릴 수 있음)
          if (exam.isScoring)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text(
                    "채점 중입니다...",
                    style: TextStyle(fontSize: 12, color: AppTheme.primaryBlue),
                  ),
                ],
              ),
            ),

          // 3. 마이크 수음 버튼 & 실시간 음성인식 스트리밍
          Center(
            child: SpeechLevelIndicator(
              isListening: exam.isListening,
              soundLevel: exam.soundLevel,
              onToggle: () {
                if (exam.isListening) {
                  exam.finishAndScoreExam();
                } else {
                  exam.startExamRecording();
                }
              },
            ),
          ),
          const SizedBox(height: 16),

          // 실시간 수음 텍스트 창
          if (exam.liveSpokenText.isNotEmpty || exam.isListening)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.record_voice_over,
                        size: 16,
                        color: AppTheme.primaryBlue,
                      ),
                      SizedBox(width: 6),
                      Text(
                        "실시간 음성 인식 중...",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    exam.liveSpokenText.isEmpty
                        ? "(말씀을 시작하세요...)"
                        : exam.liveSpokenText,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // 4. 채점 결과 성적표 리포트
          if (exam.lastResult != null)
            DiffReportWidget(result: exam.lastResult!),
        ],
      ),
    );
  }

  Widget _buildLevelChip(
    BuildContext context,
    VoiceExamProvider exam,
    TriggerDifficulty diff,
    String label,
  ) {
    final isSelected = (exam.difficulty == diff);
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : AppTheme.textDark,
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.primaryBlue,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      onSelected: (val) {
        if (val) exam.setDifficulty(diff);
      },
    );
  }
}

class _ExamHistoryTabView extends StatelessWidget {
  const _ExamHistoryTabView();

  @override
  Widget build(BuildContext context) {
    final exam = context.watch<VoiceExamProvider>();

    if (exam.history.isEmpty) {
      return const Center(
        child: Text("아직 치러진 시험 이력이 없습니다.\n모의 시험을 치르고 성적을 확인해 보세요!"),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: exam.history.length,
      itemBuilder: (ctx, idx) {
        final item = exam.history[idx];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: item.isPassed
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${item.totalScore.toStringAsFixed(0)}점 (${item.grade})",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: item.isPassed
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "일시: ${item.timestamp.year}.${item.timestamp.month}.${item.timestamp.day} ${item.timestamp.hour}:${item.timestamp.minute.toString().padLeft(2, '0')}  |  문자 일치율: ${item.charAccuracy.toStringAsFixed(0)}%  |  키워드: ${item.keywordAccuracy.toStringAsFixed(0)}%",
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
