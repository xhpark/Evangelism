import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HandOutlineWidget extends StatelessWidget {
  final int selectedIndex; // 1 ~ 5
  final bool isFollowUpMode; // false: 복음 5대 대지, true: 양육 5대 수단
  final Function(int index) onFingerSelected;

  const HandOutlineWidget({
    super.key,
    required this.selectedIndex,
    this.isFollowUpMode = false,
    required this.onFingerSelected,
  });

  static const List<Map<String, String>> _gospelFingers = [
    {"num": "1", "name": "엄지", "label": "은혜", "icon": "👍"},
    {"num": "2", "name": "검지", "label": "인간", "icon": "☝️"},
    {"num": "3", "name": "중지", "label": "하나님", "icon": "🖕"},
    {"num": "4", "name": "약지", "label": "그리스도", "icon": "💍"},
    {"num": "5", "name": "소지", "label": "믿음", "icon": "🤙"},
  ];

  static const List<Map<String, String>> _followUpFingers = [
    {"num": "1", "name": "엄지", "label": "성경", "icon": "📖"},
    {"num": "2", "name": "검지", "label": "기도", "icon": "🙏"},
    {"num": "3", "name": "중지", "label": "예배", "icon": "⛪"},
    {"num": "4", "name": "약지", "label": "교제", "icon": "🤝"},
    {"num": "5", "name": "소지", "label": "전도", "icon": "📢"},
  ];

  @override
  Widget build(BuildContext context) {
    final list = isFollowUpMode ? _followUpFingers : _gospelFingers;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isFollowUpMode ? "🖐️ 영적 성장 5대 수단 (손가락 원리)" : "🖐️ 복음 5대 핵심 개요 (Hand Outline)",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "$selectedIndex번 선택됨",
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: list.map((item) {
              final idx = int.parse(item['num']!);
              final isSelected = (selectedIndex == idx);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onFingerSelected(idx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(item['icon']!, style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 2),
                          Text(
                            item['label']!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
