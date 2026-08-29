import '../models/follow_up_model.dart';
import 'korean_text_normalizer.dart';

class QnAEvaluationResult {
  final bool isPassed;
  final String feedback;
  final String correctExample;

  QnAEvaluationResult({
    required this.isPassed,
    required this.feedback,
    required this.correctExample,
  });
}

class FollowUpEngine {
  /// 요한복음 6:47 구원의 확신 4문답 의도 매칭 평가
  static QnAEvaluationResult evaluateAssuranceResponse(int questionIndex, String spokenText) {
    if (questionIndex < 0 || questionIndex >= FollowUpData.assuranceQnAList.length) {
      return QnAEvaluationResult(
        isPassed: false,
        feedback: "잘못된 질문 인덱스입니다.",
        correctExample: "",
      );
    }

    final pair = FollowUpData.assuranceQnAList[questionIndex];
    final normSpoken = KoreanTextNormalizer.normalize(spokenText);

    bool isMatch = false;

    switch (questionIndex) {
      case 0: // Q1: 예수님을 믿으셨습니까?
        isMatch = normSpoken.contains('믿') ||
            normSpoken.contains('예수') ||
            normSpoken.contains('네') ||
            normSpoken.contains('예') ||
            normSpoken.contains('영접');
        break;

      case 1: // Q2: 지금 무엇이 있습니까?
        isMatch = normSpoken.contains('영생') ||
            normSpoken.contains('생명') ||
            normSpoken.contains('구원');
        break;

      case 2: // Q3: 어디에 들어갑니까?
        isMatch = normSpoken.contains('천국') ||
            normSpoken.contains('하나님 나라') ||
            normSpoken.contains('하늘나라');
        break;

      case 3: // Q4: 근거/이유는 무엇입니까?
        isMatch = normSpoken.contains('약속') ||
            normSpoken.contains('말씀') ||
            normSpoken.contains('예수') ||
            normSpoken.contains('십자가') ||
            normSpoken.contains('공로') ||
            normSpoken.contains('대속') ||
            normSpoken.contains('피');
        break;
    }

    if (isMatch) {
      return QnAEvaluationResult(
        isPassed: true,
        feedback: "정확합니다! 아주 훌륭한 확신 선포입니다.",
        correctExample: pair.fullExampleScript,
      );
    } else {
      return QnAEvaluationResult(
        isPassed: false,
        feedback: "핵심 단어가 빠졌습니다. 모범 답변을 확인해 보세요.",
        correctExample: pair.fullExampleScript,
      );
    }
  }

  /// 5손가락 영적 성장 수단 목록 반환
  static List<GrowthPrinciple> getGrowthPrinciples() {
    return FollowUpData.growthPrinciples;
  }
}
