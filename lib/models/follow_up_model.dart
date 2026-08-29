class DialoguePair {
  final String questionFromPartner; // 파트너/새신자의 질문 또는 리액션
  final String expectedAnswerSummary; // 전도자가 해야 할 말 핵심
  final List<String> expectedKeywords; // 전도자 답변 키워드
  final String fullExampleScript; // 모범 대본

  DialoguePair({
    required this.questionFromPartner,
    required this.expectedAnswerSummary,
    required this.expectedKeywords,
    required this.fullExampleScript,
  });
}

class GrowthPrinciple {
  final int fingerIndex; // 1: 엄지, 2: 검지, 3: 중지, 4: 약지, 5: 소지
  final String fingerName;
  final String principleName; // 성경, 기도, 예배, 교제, 전도
  final String scriptureRef; // 딤후 3:16, 빌 4:6-7 등
  final String scriptureText;
  final String meaning;
  final String actionGuide;

  GrowthPrinciple({
    required this.fingerIndex,
    required this.fingerName,
    required this.principleName,
    required this.scriptureRef,
    required this.scriptureText,
    required this.meaning,
    required this.actionGuide,
  });
}

class FollowUpData {
  static final List<DialoguePair> assuranceQnAList = [
    DialoguePair(
      questionFromPartner: "(새신자) \"아까 영접 기도를 드렸는데, 정말 저 같은 사람도 구원받은 게 맞나요?\"",
      expectedAnswerSummary: "질문 1: 방금 예수님을 믿으셨습니까?",
      expectedKeywords: ["예수님", "믿으셨습니까", "방금"],
      fullExampleScript: "선생님, 요한복음 6장 47절에 '믿는 자는 영생을 가졌나니'라고 말씀하셨습니다. 방금 예수님을 믿으셨습니까?",
    ),
    DialoguePair(
      questionFromPartner: "(새신자) \"네! 진심으로 예수님을 믿고 영접했습니다.\"",
      expectedAnswerSummary: "질문 2: 그렇다면 지금 선생님께는 무엇이 있습니까?",
      expectedKeywords: ["영생", "무엇이", "약속"],
      fullExampleScript: "그렇다면 하나님의 약속의 말씀에 의하면, 지금 선생님께는 무엇이 있습니까? (영생)",
    ),
    DialoguePair(
      questionFromPartner: "(새신자) \"네, 영생의 선물이 제게 있군요!\"",
      expectedAnswerSummary: "질문 3: 만일 오늘 밤 세상을 떠나신다면 어디에 들어가십니까?",
      expectedKeywords: ["오늘 밤", "세상", "천국", "어디"],
      fullExampleScript: "그렇습니다! 그렇다면 만일 오늘 밤이라도 세상을 떠나신다면 어디에 들어가시겠습니까? (천국)",
    ),
    DialoguePair(
      questionFromPartner: "(새신자) \"천국에 들어갑니다! 그런데 제가 죄를 또 지으면 어떻게 되죠?\"",
      expectedAnswerSummary: "질문 4: 천국에 들어갈 수 있는 근거와 이유는 무엇입니까?",
      expectedKeywords: ["이유", "근거", "예수님", "십자가", "하나님", "약속"],
      fullExampleScript: "선생님이 천국에 들어가는 근거는 선생님의 행위나 느낌이 아니라, 십자가에서 모든 죄를 완불하신 예수님의 공로와 변함없는 하나님의 약속의 말씀 때문입니다!",
    ),
  ];

  static final List<GrowthPrinciple> growthPrinciples = [
    GrowthPrinciple(
      fingerIndex: 1,
      fingerName: "엄지손가락 👍",
      principleName: "성경 (Bible)",
      scriptureRef: "디모데후서 3:16",
      scriptureText: "모든 성경은 하나님의 감동으로 된 것으로 교훈과 책망과 바르게 함과 의로 교육하기에 유익하니",
      meaning: "영적 양식",
      actionGuide: "갓난아기가 매일 젖을 먹듯, 매일 성경 말씀을 읽고 묵상하여 영적 생명을 풍성히 자라게 합니다.",
    ),
    GrowthPrinciple(
      fingerIndex: 2,
      fingerName: "검지손가락 ☝️",
      principleName: "기도 (Prayer)",
      scriptureRef: "빌립보서 4:6-7",
      scriptureText: "아무 것도 염려하지 말고 다만 모든 일에 기도와 간구로, 너희 구할 것을 감사함으로 하나님께 아뢰라",
      meaning: "영적 호흡 & 대화",
      actionGuide: "숨을 쉬지 않으면 살 수 없듯, 언제 어디서나 기도를 통해 하나님 아버지와 친밀하게 대화합니다.",
    ),
    GrowthPrinciple(
      fingerIndex: 3,
      fingerName: "가운데손가락 🖕",
      principleName: "예배 (Worship)",
      scriptureRef: "요한복음 4:24",
      scriptureText: "하나님은 영이시니 예배하는 자가 영과 진리로 예배할지니라",
      meaning: "하나님을 높임 (가장 높은 손가락)",
      actionGuide: "우리를 구원하신 하나님께 감사와 찬양을 드리며, 매주일 온 성도와 함께 교회에서 신령과 진정으로 예배합니다.",
    ),
    GrowthPrinciple(
      fingerIndex: 4,
      fingerName: "약지손가락 💍",
      principleName: "교제 (Fellowship)",
      scriptureRef: "히브리서 10:24-25",
      scriptureText: "서로 돌아보아 사랑과 선행을 격려하며 모이기를 폐하는 어떤 사람들의 습관과 같이 하지 말고",
      meaning: "사랑의 연합 (반지 끼는 손가락)",
      actionGuide: "성도들과 구역/목장 모임에서 신앙을 나누고 서로를 격려하며 하나님 가족의 사랑을 나눕니다.",
    ),
    GrowthPrinciple(
      fingerIndex: 5,
      fingerName: "새끼손가락 🤙",
      principleName: "전도 (Witness)",
      scriptureRef: "사도행전 1:8",
      scriptureText: "오직 성령이 너희에게 임하시면 너희가 권능을 받고... 내 증인이 되리라",
      meaning: "복음 증거 (약속의 손가락)",
      actionGuide: "내가 만난 예수님과 영생의 기쁜 소식을 가족, 친구, 이웃에게 담대히 전합니다.",
    ),
  ];
}
