import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/follow_up_provider.dart';
import '../widgets/hand_outline_widget.dart';
import '../widgets/speech_level_indicator.dart';
import '../theme/app_theme.dart';

class FollowUpMasterScreen extends StatelessWidget {
  const FollowUpMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final followUp = context.watch<FollowUpProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("🌟 즉석 양육 특화 마스터 훈련"),
      ),
      body: Column(
        children: [
          // 1. 상단 4단계 스테퍼 헤더
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStepTab(followUp, 0, "1단계", "생일 축하"),
                  const SizedBox(width: 4),
                  _buildStepTab(followUp, 1, "2단계", "확신 4문답"),
                  const SizedBox(width: 4),
                  _buildStepTab(followUp, 2, "3단계", "5손가락 양육"),
                  const SizedBox(width: 4),
                  _buildStepTab(followUp, 3, "4단계", "예배/책자 약속"),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // 2. 메인 컨텐츠 뷰
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildCurrentStepContent(context, followUp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTab(FollowUpProvider provider, int stepIdx, String stepLabel, String title) {
    final isSelected = (provider.currentStepIndex == stepIdx);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => provider.selectStep(stepIdx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Text(
              stepLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.primaryBlue : AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppTheme.primaryNavy : AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent(BuildContext context, FollowUpProvider provider) {
    switch (provider.currentStepIndex) {
      case 0:
        return _buildStep1Birthday(provider);
      case 1:
        return _buildStep2AssuranceRoleplay(provider);
      case 2:
        return _buildStep3FiveFingers(provider);
      case 3:
        return _buildStep4Appointment(provider);
      default:
        return const SizedBox();
    }
  }

  // Step 1: 영적 생일 축하
  Widget _buildStep1Birthday(FollowUpProvider provider) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text("🎉", style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              const Text(
                "영적 생일 선포 & 축하 멘트",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF92400E),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "\"선생님! 오늘 영생을 얻고 하나님의 자녀로 다시 태어나신 것을 진심으로 축하드립니다. 오늘은 선생님의 영적인 생일입니다!\"",
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => provider.selectStep(1),
            icon: const Icon(Icons.arrow_forward),
            label: const Text("다음: 2단계 확신 4문답 롤플레잉"),
          ),
        ),
      ],
    );
  }

  // Step 2: 요한복음 6:47 확신 4문답 대화 롤플레잉
  Widget _buildStep2AssuranceRoleplay(FollowUpProvider provider) {
    final pair = provider.currentDialoguePair;
    final result = provider.lastQnAResult;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단 가이드
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "❓ 확신 점검 ${provider.currentQnAIndex + 1} / 4 문답 (요 6:47)",
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: provider.prevQnA,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    onPressed: provider.nextQnA,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 새신자의 질문/반응 말풍선 (TTS)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "👤 새신자 (대화 상대)",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up, color: AppTheme.primaryBlue, size: 20),
                    onPressed: () => provider.playPartnerQuestion(),
                    tooltip: "새신자 목소리 듣기",
                  ),
                ],
              ),
              Text(
                pair.questionFromPartner,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryNavy,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 전도자의 핵심 미션
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "🗣️ 전도자의 답변 미션:",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
              ),
              const SizedBox(height: 4),
              Text(
                pair.expectedAnswerSummary,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textDark),
              ),
              const SizedBox(height: 8),
              Text(
                "모범 멘트: \"${pair.fullExampleScript}\"",
                style: const TextStyle(fontSize: 13, height: 1.4, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // STT 음성 수음 및 피드백 영역
        Center(
          child: SpeechLevelIndicator(
            isListening: provider.isListening,
            soundLevel: 3.0,
            onToggle: () {
              if (provider.isListening) {
                provider.stopVoiceResponse();
              } else {
                provider.startVoiceResponse();
              }
            },
          ),
        ),
        const SizedBox(height: 12),

        if (provider.userSpokenText.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              "인식된 발화: \"${provider.userSpokenText}\"",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),

        if (result != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: result.isPassed ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: result.isPassed ? AppTheme.accentEmerald : AppTheme.accentRed,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  result.isPassed ? Icons.check_circle : Icons.info,
                  color: result.isPassed ? AppTheme.accentEmerald : AppTheme.accentRed,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result.feedback,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: result.isPassed ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: provider.prevQnA,
                child: const Text("이전 문답"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: provider.nextQnA,
                child: const Text("다음 문답 ➔"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Step 3: 5손가락 영적 성장 수단 인터랙티브 뷰
  Widget _buildStep3FiveFingers(FollowUpProvider provider) {
    final p = provider.currentGrowthPrinciple;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HandOutlineWidget(
          selectedIndex: provider.selectedFingerIndex,
          isFollowUpMode: true,
          onFingerSelected: (idx) => provider.selectFinger(idx),
        ),
        const SizedBox(height: 16),

        // 선택된 손가락 상세 카드
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
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
                  Text(
                    "${p.fingerName} - ${p.principleName}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up, color: AppTheme.primaryBlue),
                    onPressed: () => provider.speakSelectedPrinciple(),
                    tooltip: "원리 설명 듣기",
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "📖 ${p.scriptureRef}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "\"${p.scriptureText}\"",
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF475569),
                ),
              ),
              const Divider(height: 24),
              Text(
                "💡 상징적 의미: ${p.meaning}",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentGold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                p.actionGuide,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => provider.selectStep(3),
            icon: const Icon(Icons.arrow_forward),
            label: const Text("다음: 4단계 예배 & 책자 약속"),
          ),
        ),
      ],
    );
  }

  // Step 4: 소책자 증정 및 주일 예배 약속
  Widget _buildStep4Appointment(FollowUpProvider provider) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.menu_book, color: AppTheme.primaryBlue),
                  SizedBox(width: 8),
                  Text(
                    "『함께 성장해요』 소책자 전달 & 예배 약속",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                "\"선생님의 신앙 성장을 돕기 위해 기초 양육 소책자(『함께 성장해요』)를 선물로 드립니다.\n이번 주일 오전 11시 교회 로비에서 뵙고 함께 기쁨으로 예배드리기를 기대합니다. 제가 주일 아침 10시 30분에 모시러 가겠습니다!\"",
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => provider.selectStep(0),
            icon: const Icon(Icons.replay),
            label: const Text("즉석 양육 처음부터 다시 훈련"),
          ),
        ),
      ],
    );
  }
}
