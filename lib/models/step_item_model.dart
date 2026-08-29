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
  });

  String get effectiveScript => (customScript != null && customScript!.trim().isNotEmpty)
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
      };

  factory StepItem.fromJson(Map<String, dynamic> json) {
    StepType parsedType;
    try {
      parsedType = StepType.values.byName(json['type'] as String? ?? 'dialogue');
    } catch (_) {
      parsedType = StepType.dialogue;
    }

    final rawKeywords = json['keywords'];
    List<String> parsedKeywords = [];
    if (rawKeywords is List) {
      parsedKeywords = rawKeywords.map((e) => e.toString()).toList();
    }

    final scriptText = json['script'] as String? ?? '';
    final isTrans = json['is_transition'] as bool? ??
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
    );
  }
}
