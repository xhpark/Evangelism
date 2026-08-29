import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SpeechLevelIndicator extends StatelessWidget {
  final bool isListening;
  final double soundLevel;
  final VoidCallback onToggle;

  const SpeechLevelIndicator({
    super.key,
    required this.isListening,
    required this.soundLevel,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final scale = isListening ? (1.0 + (soundLevel.clamp(0.0, 10.0) / 15.0)) : 1.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 100),
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isListening
                      ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                      : [AppTheme.primaryBlue, AppTheme.primaryNavy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isListening ? AppTheme.accentRed : AppTheme.primaryBlue)
                        .withOpacity(0.35),
                    blurRadius: isListening ? 20 : 10,
                    spreadRadius: isListening ? 4 : 1,
                  ),
                ],
              ),
              child: Icon(
                isListening ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isListening ? "음성 인식 중... (터치 시 채점 종료)" : "마이크를 터치하여 암송 시작",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isListening ? AppTheme.accentRed : AppTheme.textMuted,
          ),
        ),
      ],
    );
  }
}
