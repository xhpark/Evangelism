import '../models/section_model.dart';
import '../models/step_item_model.dart';

class TransitionItem {
  final int index;
  final String fromSection;
  final String toSection;
  final String transitionScript;
  final String leadIn;
  final List<String> keywords;

  /// 이 전환문장이 속한 대본 스텝 ID (대본 수정 시 추적용)
  final String stepId;

  TransitionItem({
    required this.index,
    required this.fromSection,
    required this.toSection,
    required this.transitionScript,
    required this.leadIn,
    required this.keywords,
    required this.stepId,
  });
}

/// 6대 대지 전환문장 엔진
///
/// 2026-08-29 이전에는 전환문장 6개를 이 파일에 하드코딩해 두었고, 그 사본이
/// `data/just_ee_data.json`의 대본과 어긋나 있었다(6번 전환문장은 내용 자체가 달랐다).
/// 이제는 대본 데이터의 `transition_text` 필드 하나만을 출처로 삼는다.
/// 훈련생이 설정에서 대본을 수정하면 전환문장 목록도 함께 따라간다.
class TransitionSentenceEngine {
  /// 대본 데이터에서 전환문장 목록을 구성한다. (대지 순서 유지)
  static List<TransitionItem> buildFromSections(List<Section> sections) {
    final items = <TransitionItem>[];

    for (var secIdx = 0; secIdx < sections.length; secIdx++) {
      final section = sections[secIdx];
      for (final step in section.steps) {
        if (!step.isTransition) continue;

        final nextSection =
            (secIdx + 1 < sections.length) ? sections[secIdx + 1] : null;

        items.add(TransitionItem(
          index: items.length + 1,
          fromSection: section.title,
          toSection: nextSection?.title ?? '완주',
          transitionScript: step.effectiveTransitionText,
          leadIn: _makeLeadIn(step),
          keywords: step.transitionKeywords.isNotEmpty
              ? step.transitionKeywords
              : step.keywords,
          stepId: step.stepId,
        ));
      }
    }

    return items;
  }

  static String _makeLeadIn(StepItem step) {
    final words = step.effectiveTransitionText
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';
    return '${words.take(3).join(' ')}...';
  }
}
