import 'step_item_model.dart';

class Section {
  final String id;
  final String title;
  final int?
  fingerIndex; // 1: 엄지(은혜), 2: 검지(인간), 3: 중지(하나님), 4: 약지(그리스도), 5: 소지(믿음)
  final String? fingerName;
  final List<StepItem> steps;

  Section({
    required this.id,
    required this.title,
    this.fingerIndex,
    this.fingerName,
    required this.steps,
  });

  Section copyWith({
    String? id,
    String? title,
    int? fingerIndex,
    String? fingerName,
    List<StepItem>? steps,
  }) {
    return Section(
      id: id ?? this.id,
      title: title ?? this.title,
      fingerIndex: fingerIndex ?? this.fingerIndex,
      fingerName: fingerName ?? this.fingerName,
      steps: steps ?? this.steps,
    );
  }

  String get fullCombinedScript {
    return steps.map((s) => s.effectiveScript).join(' ');
  }

  List<String> get allKeywords {
    final list = <String>[];
    for (final s in steps) {
      list.addAll(s.keywords);
    }
    return list;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    if (fingerIndex != null) 'finger_index': fingerIndex,
    if (fingerName != null) 'finger_name': fingerName,
    'steps': steps.map((s) => s.toJson()).toList(),
  };

  factory Section.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'] as List? ?? [];
    final parsedSteps = rawSteps
        .map((s) => StepItem.fromJson(s as Map<String, dynamic>))
        .toList();

    int? fIndex = json['finger_index'] as int?;
    String? fName = json['finger_name'] as String?;

    // Auto-map 5 fingers if not specified in JSON
    final sectionId = json['id'] as String? ?? '';
    if (fIndex == null) {
      if (sectionId == 'grace') {
        fIndex = 1;
        fName = '엄지손가락 (은혜)';
      } else if (sectionId == 'humanity') {
        fIndex = 2;
        fName = '검지손가락 (인간)';
      } else if (sectionId == 'god') {
        fIndex = 3;
        fName = '가운데손가락 (하나님)';
      } else if (sectionId == 'christ') {
        fIndex = 4;
        fName = '약지손가락 (그리스도)';
      } else if (sectionId == 'faith') {
        fIndex = 5;
        fName = '새끼손가락 (믿음)';
      }
    }

    return Section(
      id: sectionId,
      title: json['title'] as String? ?? '',
      fingerIndex: fIndex,
      fingerName: fName,
      steps: parsedSteps,
    );
  }
}
