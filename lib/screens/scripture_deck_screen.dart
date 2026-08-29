import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scripture_provider.dart';
import '../theme/app_theme.dart';

class ScriptureDeckScreen extends StatelessWidget {
  const ScriptureDeckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScriptureProvider>();
    final card = provider.currentCard;

    return Scaffold(
      appBar: AppBar(
        title: Text("📖 복음전문 핵심 ${provider.cards.length}구절 암송 덱"),
        actions: [
          IconButton(
            icon: Icon(
              provider.blankQuizMode ? Icons.format_strikethrough : Icons.quiz_outlined,
              color: provider.blankQuizMode ? AppTheme.accentGold : Colors.white,
            ),
            tooltip: "빈칸 퀴즈 모드 토글",
            onPressed: () => provider.toggleBlankQuizMode(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 상단 구절 인덱스 캐러셀 칩
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(provider.cards.length, (idx) {
                  final c = provider.cards[idx];
                  final isSelected = (idx == provider.currentIndex);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ChoiceChip(
                      label: Text(
                        c.reference.split(' ').take(2).join(' '),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : AppTheme.textDark,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryBlue,
                      onSelected: (_) => provider.selectCard(idx),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            // 메인 성경 카드
            if (card == null)
              const Center(child: Text("구절 데이터가 없습니다."))
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
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
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            card.category,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.volume_up, color: AppTheme.primaryBlue),
                          onPressed: () => provider.speakCurrentVerse(),
                          tooltip: "성경 구절 듣기",
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Text(
                      card.reference,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryNavy,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Divider(height: 24),

                    // 본문 (빈칸 모드 또는 일반 모드)
                    if (provider.showText)
                      Text(
                        provider.blankQuizMode
                            ? _maskBlanks(card.text, card.blankWords)
                            : card.text,
                        style: const TextStyle(
                          fontSize: 17,
                          height: 1.65,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                        textAlign: TextAlign.center,
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          "가림막 적용 중\n(아래 버튼을 눌러 본문 확인)",
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "💡 교리적 의미: ${card.meaning}",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // 하단 버튼 바 (한 줄 줄바꿈 방지 및 최적화된 패딩)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: provider.prevCard,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chevron_left, size: 18),
                        SizedBox(width: 2),
                        Text(
                          "이전 구절",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  onPressed: () => provider.toggleShowText(),
                  icon: Icon(provider.showText ? Icons.visibility_off : Icons.visibility, size: 20),
                  tooltip: "본문 가리기/보기",
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton(
                    onPressed: provider.nextCard,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "다음 구절",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _maskBlanks(String fullText, List<String> blankWords) {
    String masked = fullText;
    for (final b in blankWords) {
      masked = masked.replaceAll(b, " [  ___  ] ");
    }
    return masked;
  }
}
