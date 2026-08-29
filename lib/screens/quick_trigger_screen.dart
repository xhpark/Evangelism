import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quick_trigger_provider.dart';
import '../services/quick_trigger_engine.dart';
import '../services/transition_sentence_engine.dart';
import '../widgets/speech_level_indicator.dart';
import '../theme/app_theme.dart';

class QuickTriggerScreen extends StatefulWidget {
  const QuickTriggerScreen({super.key});

  @override
  State<QuickTriggerScreen> createState() => _QuickTriggerScreenState();
}

class _QuickTriggerScreenState extends State<QuickTriggerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuickTriggerProvider>().initDeck();
    });
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
        title: const Text("순발력 & 전환문장 트레이닝"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentGold,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: "⚡ STT 순발력 훈련"),
            Tab(text: "🔗 6대 전환문장 덱"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _QuickTriggerTabView(),
          _TransitionDeckTabView(),
        ],
      ),
    );
  }
}

class _QuickTriggerTabView extends StatelessWidget {
  const _QuickTriggerTabView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuickTriggerProvider>();
    final card = provider.currentCard;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 1. 난이도 및 옵션 바
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 난이도 선택 (고급 3단어 / 중급 4단어 / 초급 5단어)
              DropdownButton<TriggerDifficulty>(
                value: provider.difficulty,
                underline: const SizedBox(),
                items: TriggerDifficulty.values.map((d) {
                  return DropdownMenuItem(
                    value: d,
                    child: Text(
                      d.label,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (d) {
                  if (d != null) provider.setDifficulty(d);
                },
              ),

              // 전환문장만 필터 토글
              FilterChip(
                label: const Text("전환문장만 출제", style: TextStyle(fontSize: 11)),
                selected: provider.onlyTransitions,
                selectedColor: AppTheme.accentGold.withValues(alpha: 0.2),
                checkmarkColor: AppTheme.accentGold,
                onSelected: (val) => provider.toggleTransitionOnly(val),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 2. 진행 상태 바
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "카드 ${provider.currentIndex + 1} / ${provider.totalCards}",
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              if (card != null && provider.mistakeIds.contains(card.stepId))
                const Row(
                  children: [
                    Icon(Icons.bookmark, size: 14, color: AppTheme.accentRed),
                    SizedBox(width: 2),
                    Text(
                      "오답노트 등록됨",
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.accentRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. 타이머 프로그레스 바
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: provider.difficulty.durationSeconds > 0
                  ? (provider.remainingSeconds / provider.difficulty.durationSeconds)
                  : 0.0,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                provider.remainingSeconds <= 0.3
                    ? AppTheme.accentRed
                    : AppTheme.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. 메인 문제 카드
          if (card == null)
            const Center(child: Text("출제할 카드가 없습니다."))
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      card.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 문제 선두 단어 (고급=3단어, 중급=4단어, 초급=5단어)
                  Text(
                    QuickTriggerEngine.extractLeadIn(
                      card.effectiveScript,
                      difficulty: provider.difficulty,
                    ),
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryNavy,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // 남은 타이머 시간
                  if (provider.cardState == TriggerCardState.countdown)
                    Text(
                      provider.remainingSeconds > 0
                          ? "${provider.remainingSeconds.toStringAsFixed(1)} 초"
                          : "타임 오버! 이어서 계속 말씀하세요",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: provider.remainingSeconds > 0
                            ? AppTheme.accentRed
                            : AppTheme.textMuted,
                      ),
                    ),

                  // 정답 노출 영역 (Revealed 상태)
                  if (provider.cardState == TriggerCardState.revealed) ...[
                    const Divider(height: 20),
                    const Text(
                      "📖 전체 원문 대본:",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.effectiveScript,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.55,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 16),

          // 5. STT 음성 인식 & 마이크 상태 표시
          if (provider.cardState == TriggerCardState.countdown) ...[
            Center(
              child: SpeechLevelIndicator(
                isListening: provider.isListening,
                soundLevel: 4.0,
                onToggle: () => provider.finishAndScore(),
              ),
            ),
            const SizedBox(height: 10),
            if (provider.spokenText.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  "실시간 인식: \"${provider.spokenText}\"",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
          ],

          // 6. 평가 결과: 듀얼 점수 카드 (순발력 점수 + 정확성 점수)
          if (provider.cardState == TriggerCardState.revealed && provider.evalResult != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 2가지 점수 나란히 비교 표시
                  Row(
                    children: [
                      // ⚡ 1. 순발력 점수
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "⚡ 순발력 점수",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${provider.speedScore.toStringAsFixed(0)}점",
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                              Text(
                                "반응 속도: ${provider.reactionTimeSeconds.toStringAsFixed(2)}초",
                                style: const TextStyle(fontSize: 11, color: Color(0xFF78350F)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // 🎯 2. 정확성 점수
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: provider.accuracyScore >= 80
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "🎯 정확성 점수",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: provider.accuracyScore >= 80
                                      ? const Color(0xFF065F46)
                                      : const Color(0xFF991B1B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${provider.accuracyScore.toStringAsFixed(0)}점",
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: provider.accuracyScore >= 80
                                      ? const Color(0xFF047857)
                                      : const Color(0xFFDC2626),
                                ),
                              ),
                              Text(
                                "일치율: ${provider.evalResult!.charAccuracy.toStringAsFixed(0)}%",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: provider.accuracyScore >= 80
                                      ? const Color(0xFF047857)
                                      : const Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (provider.spokenText.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "인식된 발화: \"${provider.spokenText}\"",
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 7. 하단 버튼 액션
          if (provider.cardState == TriggerCardState.ready)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => provider.startTimerAndSTT(),
                icon: const Icon(Icons.mic),
                label: Text(
                  "${provider.difficulty.durationSeconds.toStringAsFixed(0)}초 순발력 테스트 & 음성 인식 시작",
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            )
          else if (provider.cardState == TriggerCardState.countdown)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => provider.finishAndScore(),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
                icon: const Icon(Icons.stop),
                label: const Text("답변 완료 및 자동 채점하기"),
              ),
            )
          else if (provider.cardState == TriggerCardState.revealed)
            // 두 가지 점수 아래에 위치한 '다음 카드 넘기기' 버튼
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => provider.nextCard(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.arrow_forward),
                label: const Text(
                  "다음 카드 넘기기 ➔",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TransitionDeckTabView extends StatelessWidget {
  const _TransitionDeckTabView();

  @override
  Widget build(BuildContext context) {
    final list = TransitionSentenceEngine.getAllTransitions();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (ctx, idx) {
        final item = list[idx];

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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "전환 ${item.index}",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                    Text(
                      "${item.fromSection} ➔ ${item.toSection}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.transitionScript,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
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
