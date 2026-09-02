enum DiffType {
  matched, // 일치 (초록색)
  missing, // 누락 (빨간색 취소선)
  extra, // 추가/오인식 (주황색)
  substituted, // 대체 (노란색/주황색)
}

class DiffToken {
  final String text;
  final DiffType type;
  final String? originalText; // 대체(substituted)인 경우 원래 텍스트

  DiffToken({required this.text, required this.type, this.originalText});

  Map<String, dynamic> toJson() => {
    'text': text,
    'type': type.name,
    if (originalText != null) 'originalText': originalText,
  };

  factory DiffToken.fromJson(Map<String, dynamic> json) => DiffToken(
    text: json['text'] as String,
    type: DiffType.values.byName(json['type'] as String),
    originalText: json['originalText'] as String?,
  );
}
