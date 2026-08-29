class TransitionItem {
  final int index;
  final String fromSection;
  final String toSection;
  final String transitionScript;
  final String leadIn;
  final List<String> keywords;

  TransitionItem({
    required this.index,
    required this.fromSection,
    required this.toSection,
    required this.transitionScript,
    required this.leadIn,
    required this.keywords,
  });
}

class TransitionSentenceEngine {
  static final List<TransitionItem> transitions = [
    TransitionItem(
      index: 1,
      fromSection: "1. 서론 (진단질문)",
      toSection: "2.1 은혜 (Grace)",
      transitionScript:
          "선생님, 제가 어떻게 영생을 얻게 되었는지, 선생님도 어떻게 하면 저희들처럼 영생을 얻어 천국에 들어간다는 것을 확신할 수 있는지 말씀드려도 되겠습니까?",
      leadIn: "선생님 제가 어떻게...",
      keywords: ["영생", "천국", "확신", "말씀드려도"],
    ),
    TransitionItem(
      index: 2,
      fromSection: "2.1 은혜 (Grace)",
      toSection: "2.2 인간 (Humanity)",
      transitionScript:
          "그렇다면 하나님은 영생을 왜 선물로 주셔야만 할까요? 이것은 성경이 인간에 관하여 하신 말씀을 잘 이해할 때 좀 더 분명히 알 수 있습니다.",
      leadIn: "그렇다면 하나님은 영생을...",
      keywords: ["하나님", "영생", "선물", "인간", "성경"],
    ),
    TransitionItem(
      index: 3,
      fromSection: "2.2 인간 (Humanity)",
      toSection: "2.3 하나님 (God)",
      transitionScript:
          "그렇다면 이런 죄인이 어떻게 영생을 선물로 받을 수 있을까요? 이것은 성경이 하나님에 관하여 하신 말씀을 잘 이해할 때 좀 더 분명히 알 수 있습니다.",
      leadIn: "그렇다면 이런 죄인이...",
      keywords: ["죄인", "영생", "선물", "하나님", "성경"],
    ),
    TransitionItem(
      index: 4,
      fromSection: "2.3 하나님 (God)",
      toSection: "2.4 그리스도 (Christ)",
      transitionScript:
          "이처럼 자비로우시고 의로우신 하나님은 우리의 죄 문제를 예수 그리스도 안에서 단번에 해결하셨습니다.",
      leadIn: "이처럼 자비로우시고 의로우신...",
      keywords: ["자비", "의로우신 하나님", "죄 문제", "예수 그리스도", "단번에 해결"],
    ),
    TransitionItem(
      index: 5,
      fromSection: "2.4 그리스도 (Christ)",
      toSection: "2.5 믿음 (Faith)",
      transitionScript:
          "지금 예수님은 영생을 선물로 주시고자 하십니다. 그렇다면 우리가 이 영생의 선물을 어떻게 받을 수가 있을까요? 이 영생의 선물은 오직 예수 그리스도를 믿음으로 받습니다.",
      leadIn: "지금 예수님은 영생을...",
      keywords: ["예수님", "영생", "선물", "믿음", "예수 그리스도"],
    ),
    TransitionItem(
      index: 6,
      fromSection: "2.5 믿음 (Faith)",
      toSection: "3. 결신 (Commitment)",
      transitionScript:
          "선생님께서 영생을 선물로 받고 천국에 들어가려면 신뢰의 대상을 자신의 선한 행위로부터 오직 예수 그리스도께로 옮기셔야만 합니다.",
      leadIn: "선생님께서 영생을 선물로...",
      keywords: ["영생", "선물", "천국", "신뢰의 대상", "선한 행위", "예수 그리스도"],
    ),
  ];

  static List<TransitionItem> getAllTransitions() => transitions;

  static TransitionItem? getTransitionByFromSection(String fromSec) {
    try {
      return transitions.firstWhere((t) => t.fromSection.contains(fromSec));
    } catch (_) {
      return null;
    }
  }
}
