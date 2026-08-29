import '../models/step_item_model.dart';

enum TriggerDifficulty {
  beginner(3.0, '초급 (5단어 / 3.0초)'),
  intermediate(2.0, '중급 (4단어 / 2.0초)'),
  master(1.0, '고급 마스터 (3단어 / 1.0초)');

  final double durationSeconds;
  final String label;
  const TriggerDifficulty(this.durationSeconds, this.label);
}

enum TriggerCardState {
  ready,
  countdown,
  revealed,
}

class QuickTriggerEngine {
  /// 난이도별 제시 단어(어절) 수 반환
  /// 고급=3단어, 중급=4단어, 초급=5단어
  static int getWordCountForDifficulty(TriggerDifficulty difficulty) {
    switch (difficulty) {
      case TriggerDifficulty.master:
        return 3;
      case TriggerDifficulty.intermediate:
        return 4;
      case TriggerDifficulty.beginner:
        return 5;
    }
  }

  /// 문장 선두부(Lead-in text) 난이도별 가변 추출
  static String extractLeadIn(String script, {TriggerDifficulty difficulty = TriggerDifficulty.master}) {
    if (script.isEmpty) return '';
    final words = script.split(' ').where((w) => w.isNotEmpty).toList();
    final count = getWordCountForDifficulty(difficulty);
    if (words.length <= count) return '$script...';
    return '${words.take(count).join(' ')}...';
  }

  /// 전체 스텝 리스트를 셔플하여 순발력 테스트 카드 덱 생성
  static List<StepItem> generateDeck(List<StepItem> allSteps, {bool onlyTransitions = false}) {
    List<StepItem> pool = allSteps;
    if (onlyTransitions) {
      pool = allSteps.where((s) => s.isTransition).toList();
    }
    final copy = List<StepItem>.from(pool);
    copy.shuffle();
    return copy;
  }
}
