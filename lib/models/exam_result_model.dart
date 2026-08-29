import 'diff_token.dart';

class ExamAreaScore {
  final String areaName; // 교리, 성경구절, 전환문장, 예화, 즉석양육
  final double score;
  final double maxScore;

  ExamAreaScore({
    required this.areaName,
    required this.score,
    required this.maxScore,
  });

  Map<String, dynamic> toJson() => {
        'areaName': areaName,
        'score': score,
        'maxScore': maxScore,
      };

  factory ExamAreaScore.fromJson(Map<String, dynamic> json) => ExamAreaScore(
        areaName: json['areaName'] as String,
        score: (json['score'] as num).toDouble(),
        maxScore: (json['maxScore'] as num).toDouble(),
      );
}

class ExamResult {
  final String examId;
  final String title;
  final DateTime timestamp;
  final double totalScore; // 0 ~ 100
  final double charAccuracy;
  final double keywordAccuracy;
  final String originalText;
  final String spokenText;
  final List<DiffToken> diffTokens;
  final List<ExamAreaScore>? areaScores; // 모의 구두시험 세부 영역 성적

  ExamResult({
    required this.examId,
    required this.title,
    required this.timestamp,
    required this.totalScore,
    required this.charAccuracy,
    required this.keywordAccuracy,
    required this.originalText,
    required this.spokenText,
    required this.diffTokens,
    this.areaScores,
  });

  bool get isPassed => totalScore >= 80.0;

  String get grade {
    if (totalScore >= 95) return 'A+ (탁월함)';
    if (totalScore >= 90) return 'A (우수함)';
    if (totalScore >= 80) return 'B (합격 수준)';
    if (totalScore >= 70) return 'C (보완 필요)';
    return 'D (재훈련 권장)';
  }

  Map<String, dynamic> toJson() => {
        'examId': examId,
        'title': title,
        'timestamp': timestamp.toIso8601String(),
        'totalScore': totalScore,
        'charAccuracy': charAccuracy,
        'keywordAccuracy': keywordAccuracy,
        'originalText': originalText,
        'spokenText': spokenText,
        'diffTokens': diffTokens.map((t) => t.toJson()).toList(),
        if (areaScores != null)
          'areaScores': areaScores!.map((a) => a.toJson()).toList(),
      };

  factory ExamResult.fromJson(Map<String, dynamic> json) {
    final rawTokens = json['diffTokens'] as List? ?? [];
    final tokens = rawTokens
        .map((t) => DiffToken.fromJson(t as Map<String, dynamic>))
        .toList();

    List<ExamAreaScore>? areas;
    if (json['areaScores'] is List) {
      areas = (json['areaScores'] as List)
          .map((a) => ExamAreaScore.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    return ExamResult(
      examId: json['examId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      totalScore: (json['totalScore'] as num?)?.toDouble() ?? 0.0,
      charAccuracy: (json['charAccuracy'] as num?)?.toDouble() ?? 0.0,
      keywordAccuracy: (json['keywordAccuracy'] as num?)?.toDouble() ?? 0.0,
      originalText: json['originalText'] as String? ?? '',
      spokenText: json['spokenText'] as String? ?? '',
      diffTokens: tokens,
      areaScores: areas,
    );
  }
}
