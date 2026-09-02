import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/step_item_model.dart';
import '../theme/app_theme.dart';

class SentenceCard extends StatefulWidget {
  final StepItem step;
  final bool isActive;
  final bool isBlindMode;
  final VoidCallback onPlay;
  final Future<void> Function(String newText)? onEdit;

  const SentenceCard({
    super.key,
    required this.step,
    required this.isActive,
    required this.isBlindMode,
    required this.onPlay,
    this.onEdit,
  });

  @override
  State<SentenceCard> createState() => _SentenceCardState();
}

class _SentenceCardState extends State<SentenceCard> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final isFocused = widget.isActive;
    final isTransition = widget.step.isTransition;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isFocused ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused
              ? AppTheme.primaryBlue
              : isTransition
              ? AppTheme.accentGold.withValues(alpha: 0.5)
              : Colors.grey.shade200,
          width: isFocused ? 2.0 : 1.0,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (widget.isBlindMode) {
              setState(() {
                _revealed = !_revealed;
              });
            } else {
              widget.onPlay();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 카드 상단 헤더 (타입 배지 & 액션 버튼들)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildTypeBadge(widget.step),
                          if (isTransition)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentGold.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "🔗 전환문장",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 문장 개별 듣기 버튼
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          icon: Icon(
                            isFocused
                                ? Icons.volume_up
                                : Icons.volume_down_outlined,
                            color: isFocused
                                ? AppTheme.primaryBlue
                                : AppTheme.textMuted,
                            size: 20,
                          ),
                          onPressed: widget.onPlay,
                          tooltip: "이 문장 듣기",
                        ),

                        // 문장 수정 버튼 (직접 편집 가능)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          icon: const Icon(
                            Icons.edit_note,
                            color: AppTheme.primaryBlue,
                            size: 22,
                          ),
                          onPressed: () => _showEditDialog(context),
                          tooltip: "문장 수정",
                        ),

                        // 복사 메뉴
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 32,
                          ),
                          onSelected: (val) {
                            if (val == 'copy') {
                              Clipboard.setData(
                                ClipboardData(
                                  text: widget.step.effectiveScript,
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("클립보드에 복사되었습니다.")),
                              );
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'copy',
                              child: Row(
                                children: [
                                  Icon(Icons.copy, size: 16),
                                  SizedBox(width: 8),
                                  Text("텍스트 복사"),
                                ],
                              ),
                            ),
                          ],
                          child: const Icon(
                            Icons.more_vert,
                            size: 18,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 본문 텍스트 (블라인드 모드 처리)
                Stack(
                  children: [
                    Text(
                      widget.step.effectiveScript,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.55,
                        fontWeight: isFocused
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isFocused
                            ? AppTheme.textDark
                            : const Color(0xFF334155),
                      ),
                    ),
                    if (widget.isBlindMode && !_revealed)
                      Positioned.fill(
                        child: ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Container(
                              alignment: Alignment.center,
                              color: Colors.white.withValues(alpha: 0.7),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.touch_app,
                                    size: 16,
                                    color: AppTheme.primaryBlue,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "탭하여 원문 확인",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // 성경 구절 레퍼런스 표기
                if (widget.step.reference != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "📖 ${widget.step.reference}",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 괄호가 포함된 소제목은 괄호 앞을 개행(\n)하여
  /// 괄호 전체가 온전하게 다음 줄로 일괄 줄바꿈되도록 처리
  static String _formatBadgeWithParenthesesWrap(String text) {
    if (text.contains('(')) {
      return text.replaceAll(RegExp(r'\s*\('), '\n(').trim();
    }
    return text;
  }

  Widget _buildTypeBadge(StepItem step) {
    Color bg;
    Color fg;
    String label = _formatBadgeWithParenthesesWrap(step.name);

    switch (step.type) {
      case StepType.verse:
        bg = Colors.purple.shade50;
        fg = Colors.purple.shade700;
        break;
      case StepType.illustration:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        break;
      case StepType.question:
        bg = Colors.indigo.shade50;
        fg = Colors.indigo.shade700;
        break;
      case StepType.prayer:
        bg = Colors.teal.shade50;
        fg = Colors.teal.shade700;
        break;
      default:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: fg,
          height: 1.25,
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: widget.step.effectiveScript);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.edit_note, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "${widget.step.name} 수정",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            maxLines: 8,
            style: const TextStyle(fontSize: 14, height: 1.45),
            decoration: const InputDecoration(
              hintText: "원하시는 대본 텍스트를 입력하세요.",
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("취소"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newText = controller.text.trim();
              if (newText.isNotEmpty) {
                await widget.onEdit?.call(newText);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("문장이 성공적으로 수정되어 저장되었습니다.")),
                );
              }
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text("저장 및 즉시 반영"),
          ),
        ],
      ),
    );
  }
}
