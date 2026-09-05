import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/study_provider.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

class AudioControlBar extends StatelessWidget {
  const AudioControlBar({super.key});

  static const List<double> _speeds = [0.8, 1.0, 1.2, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    final study = context.watch<StudyProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. 배속 선택기 (Expanded 반응형 레이아웃)
            Row(
              children: [
                const Text(
                  "배속",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: _speeds.map((s) {
                      final isSelected = (study.speedRate == s);
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => study.setSpeedRate(s),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryBlue
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryBlue
                                      : const Color(0xFFCBD5E1),
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                "${s.toStringAsFixed(1)}x",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textDark,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 2. 재생 컨트롤 버튼 줄 (4대 재생 모드)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 재생 모드 선택 드롭다운
                PopupMenuButton<PlayMode>(
                  initialValue: study.playMode,
                  onSelected: (mode) => study.setPlayMode(mode),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: PlayMode.sectionRepeat,
                      child: Row(
                        children: [
                          Icon(
                            Icons.repeat,
                            size: 18,
                            color: AppTheme.primaryBlue,
                          ),
                          SizedBox(width: 8),
                          Text("현재 챕터 무한 반복 (추천)"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: PlayMode.sectionPlay,
                      child: Row(
                        children: [
                          Icon(Icons.playlist_play, size: 18),
                          SizedBox(width: 8),
                          Text("현재 챕터 1회 재생"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: PlayMode.singleRepeat,
                      child: Row(
                        children: [
                          Icon(Icons.repeat_one, size: 18),
                          SizedBox(width: 8),
                          Text("선택문장 무한 반복"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: PlayMode.allSequentialPlay,
                      child: Row(
                        children: [
                          Icon(Icons.all_inclusive, size: 18),
                          SizedBox(width: 8),
                          Text("전체 전문(1~8) 완주 재생"),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          study.playMode == PlayMode.singleRepeat
                              ? Icons.repeat_one
                              : study.playMode == PlayMode.sectionRepeat
                              ? Icons.repeat
                              : study.playMode == PlayMode.allSequentialPlay
                              ? Icons.all_inclusive
                              : Icons.playlist_play,
                          size: 16,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          study.playMode == PlayMode.singleRepeat
                              ? "선택문장 반복"
                              : study.playMode == PlayMode.sectionRepeat
                              ? "챕터 무한반복"
                              : study.playMode == PlayMode.allSequentialPlay
                              ? "전체 완주"
                              : "챕터 1회",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 16),
                      ],
                    ),
                  ),
                ),

                // 중앙 큰 재생/정지 버튼
                ElevatedButton.icon(
                  onPressed: () {
                    if (study.isPlaying) {
                      study.stopAudio();
                    } else {
                      study.playContinuous();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: study.isPlaying
                        ? AppTheme.accentRed
                        : AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 10,
                    ),
                  ),
                  icon: Icon(
                    study.isPlaying ? Icons.stop : Icons.play_arrow,
                    size: 22,
                  ),
                  label: Text(
                    study.isPlaying ? "정지" : "연속 듣기",
                    style: const TextStyle(fontSize: 14),
                  ),
                ),

                // 블라인드(가림막) 토글
                IconButton(
                  tooltip: "블라인드(가림막) 모드",
                  onPressed: () => study.toggleBlindMode(),
                  icon: Icon(
                    study.blindMode ? Icons.visibility_off : Icons.visibility,
                    color: study.blindMode
                        ? AppTheme.accentGold
                        : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
