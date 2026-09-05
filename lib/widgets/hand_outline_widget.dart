import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HandOutlineWidget extends StatelessWidget {
  final int selectedIndex; // 1 ~ 5
  final Function(int index) onFingerSelected;

  const HandOutlineWidget({
    super.key,
    required this.selectedIndex,
    required this.onFingerSelected,
  });

  static const List<Map<String, String>> _gospelFingers = [
    {"num": "1", "name": "엄지", "label": "은혜", "icon": "👍"},
    {"num": "2", "name": "검지", "label": "인간", "icon": "☝️"},
    {"num": "3", "name": "중지", "label": "하나님", "icon": "🖕"},
    {"num": "4", "name": "약지", "label": "그리스도", "icon": "💍"},
    {"num": "5", "name": "소지", "label": "믿음", "icon": "🤙"},
  ];

  @override
  Widget build(BuildContext context) {
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
              const Expanded(
                child: Text(
                  "🖐️ 복음 5대 핵심 개요 (Hand Outline)",
                  style: TextStyle(
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
            children: _gospelFingers.map((item) {
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
                        color: isSelected
                            ? AppTheme.primaryBlue
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryBlue
                              : Colors.grey.shade300,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item['icon']!,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['label']!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textDark,
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
