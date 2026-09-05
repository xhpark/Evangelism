import '../models/step_item_model.dart';

enum TriggerDifficulty {
  beginner(1.0, '초급 (5단어 / 1.0x)'),
  intermediate(1.2, '중급 (4단어 / 1.2x)'),
  master(1.5, '고급 마스터 (3단어 / 1.5x)');

  final double speedRate;
  final String label;
  const TriggerDifficulty(this.speedRate, this.label);

  /// 기존 호환용 기본 시간 (문장 미지정 시 fallback)
  double get durationSeconds => switch (this) {
    TriggerDifficulty.beginner => 3.0,
    TriggerDifficulty.intermediate => 2.0,
    TriggerDifficulty.master => 1.0,
  };
}

enum TriggerCardState { ready, countdown, revealed }

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
  static String extractLeadIn(
    String script, {
    TriggerDifficulty difficulty = TriggerDifficulty.master,
  }) {
    if (script.isEmpty) return '';
    final words = script.split(' ').where((w) => w.isNotEmpty).toList();
    final count = getWordCountForDifficulty(difficulty);
    if (words.length <= count) return '$script...';
    return '${words.take(count).join(' ')}...';
  }

  /// 순발력 트레이닝용 문제 제시 텍스트 (시작 단어 ... 끝 단어)
  /// 초중고급 난이도에 따라 첫 5/4/3단어와 마지막 5/4/3단어를 함께 제시하여
  /// 암송의 시작점과 종착점을 명확히 파악할 수 있도록 힌트 생성
  static String extractPrompt(
    String script, {
    TriggerDifficulty difficulty = TriggerDifficulty.master,
  }) {
    final clean = script.trim();
    if (clean.isEmpty) return '';
    final words = clean.split(' ').where((w) => w.isNotEmpty).toList();
    final count = getWordCountForDifficulty(difficulty);

    if (words.length <= count) {
      return clean;
    }

    final head = words.take(count).join(' ');
    // 시작 단어들과 겹치지 않는 선에서 마지막 count개 단어 추출
    final availableTail = words.length - count;
    final tailCount = availableTail < count ? availableTail : count;
    final tail = words.sublist(words.length - tailCount).join(' ');

    return '$head ... $tail';
  }

  /// 문장 낭독 소요 시간(초) 계산
  /// 1.0x 속도 기준: 초당 5.0음절 + 쉼표(0.25초) 및 문장부호(0.4초) 휴지기
  /// 난이도별 배속: 초급 1.0x, 중급 1.2x, 고급 1.5x
  static double calculateReadingDuration(
    String script, {
    double speedRate = 1.0,
  }) {
    final clean = script.trim();
    if (clean.isEmpty) return 3.0;

    // 한글 음절 및 숫자, 알파벳 음절 수
    final syllables = RegExp(r'[가-힣0-9a-zA-Z]').allMatches(clean).length;
    final commas = RegExp(r'[,،]').allMatches(clean).length;
    final periods = RegExp(r'[.?!~;]').allMatches(clean).length;

    // 1.0x 속도 기준: 5.0 음절/초 (TTSService 표준과 일치)
    final speechSec = syllables / 5.0;
    final pauseSec = (commas * 0.25) + (periods * 0.4);

    final total1x = speechSec + pauseSec;
    final effectiveSpeed = speedRate > 0 ? speedRate : 1.0;
    final duration = total1x / effectiveSpeed;

    // 최소 2.0초 보장 및 소수점 1자리 반올림
    final rounded = double.parse(duration.toStringAsFixed(1));
    return rounded < 2.0 ? 2.0 : rounded;
  }

  /// 특정 카드와 난이도에 따른 동적 타임아웃 시간 계산
  static double getTimeoutForStep(
    StepItem step,
    TriggerDifficulty difficulty,
  ) {
    return calculateReadingDuration(
      step.effectiveScript,
      speedRate: difficulty.speedRate,
    );
  }

  /// 전체 스텝 리스트를 셔플하여 순발력 테스트 카드 덱 생성
  static List<StepItem> generateDeck(
    List<StepItem> allSteps, {
    bool onlyTransitions = false,
  }) {
    List<StepItem> pool = allSteps;
    if (onlyTransitions) {
      pool = allSteps.where((s) => s.isTransition).toList();
    }
    final copy = List<StepItem>.from(pool);
    copy.shuffle();
    return copy;
  }
}
