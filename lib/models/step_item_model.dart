enum StepType {
  dialogue,
  question,
  truth,
  verse,
  illustration,
  transition,
  prayer,
  assurance,
  celebration,
  explanation,
}

class StepItem {
  final String stepId;
  final String name;
  final StepType type;
  final String summary;
  final String script;
  String? customScript;
  final String? reference;
  final List<String> keywords;
  final String? leadInText;
  final bool isTransition;

  /// 이 단락 안에서 '다음 대지로 넘어가는 순수 전환문장'만 따로 뽑아둔 값.
  /// 순발력 탭의 전환문장 덱과 학습 대본이 서로 어긋나지 않도록 데이터에서 함께 관리한다.
  final String? transitionText;
  final List<String> transitionKeywords;

  StepItem({
    required this.stepId,
    required this.name,
    required this.type,
    required this.summary,
    required this.script,
    this.customScript,
    this.reference,
    this.keywords = const [],
    this.leadInText,
    this.isTransition = false,
    this.transitionText,
    this.transitionKeywords = const [],
  });

  /// 사용자가 대본을 수정하면 수정본에서 전환문장을 다시 찾아 반환한다.
  /// (수정본에 원래 전환문장이 남아 있지 않으면 마지막 문장을 전환문장으로 본다.)
  String get effectiveTransitionText {
    final base = transitionText;
    final current = effectiveScript;

    if (base == null || base.isEmpty) return current;
    if (current.contains(base)) return base;

    final sentences = current
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((e) => e.trim().isNotEmpty)
        .toList();
    return sentences.isNotEmpty ? sentences.last.trim() : current;
  }

  String get effectiveScript =>
      (customScript != null && customScript!.trim().isNotEmpty)
      ? customScript!
      : script;

  StepItem copyWith({
    String? stepId,
    String? name,
    StepType? type,
    String? summary,
    String? script,
    String? customScript,
    String? reference,
    List<String>? keywords,
    String? leadInText,
    bool? isTransition,
    String? transitionText,
    List<String>? transitionKeywords,
  }) {
    return StepItem(
      stepId: stepId ?? this.stepId,
      name: name ?? this.name,
      type: type ?? this.type,
      summary: summary ?? this.summary,
      script: script ?? this.script,
      customScript: customScript ?? this.customScript,
      reference: reference ?? this.reference,
      keywords: keywords ?? this.keywords,
      leadInText: leadInText ?? this.leadInText,
      isTransition: isTransition ?? this.isTransition,
      transitionText: transitionText ?? this.transitionText,
      transitionKeywords: transitionKeywords ?? this.transitionKeywords,
    );
  }

  Map<String, dynamic> toJson() => {
    'step_id': stepId,
    'name': name,
    'type': type.name,
    'summary': summary,
    'script': script,
    if (customScript != null) 'custom_script': customScript,
    if (reference != null) 'reference': reference,
    'keywords': keywords,
    if (leadInText != null) 'lead_in_text': leadInText,
    'is_transition': isTransition,
    if (transitionText != null) 'transition_text': transitionText,
    if (transitionKeywords.isNotEmpty)
      'transition_keywords': transitionKeywords,
  };

  factory StepItem.fromJson(Map<String, dynamic> json) {
    StepType parsedType;
    try {
      parsedType = StepType.values.byName(
        json['type'] as String? ?? 'dialogue',
      );
    } catch (_) {
      parsedType = StepType.dialogue;
    }

    final rawKeywords = json['keywords'];
    List<String> parsedKeywords = [];
    if (rawKeywords is List) {
      parsedKeywords = rawKeywords.map((e) => e.toString()).toList();
    }

    final rawTransKeywords = json['transition_keywords'];
    List<String> parsedTransKeywords = [];
    if (rawTransKeywords is List) {
      parsedTransKeywords = rawTransKeywords.map((e) => e.toString()).toList();
    }

    final scriptText = json['script'] as String? ?? '';
    final isTrans =
        json['is_transition'] as bool? ??
        (parsedType == StepType.transition ||
            json['name']?.toString().contains('전환') == true);

    String? leadIn = json['lead_in_text'] as String?;
    if (leadIn == null || leadIn.isEmpty) {
      final words = scriptText.split(' ');
      leadIn = words.take(2).join(' ');
      if (leadIn.isNotEmpty) leadIn += '...';
    }

    return StepItem(
      stepId: json['step_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: parsedType,
      summary: json['summary'] as String? ?? '',
      script: scriptText,
      customScript: json['custom_script'] as String?,
      reference: json['reference'] as String?,
      keywords: parsedKeywords,
      leadInText: leadIn,
      isTransition: isTrans,
      transitionText: json['transition_text'] as String?,
      transitionKeywords: parsedTransKeywords,
    );
  }
}
