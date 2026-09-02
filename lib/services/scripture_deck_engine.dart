class ScriptureCard {
  final int id;
  final String category; // 은혜, 인간, 하나님, 그리스도, 믿음, 결신/확신, 양육
  final String reference;
  final String text;
  final String meaning;
  final List<String> blankWords; // 빈칸 퀴즈용 가림 단어

  ScriptureCard({
    required this.id,
    required this.category,
    required this.reference,
    required this.text,
    required this.meaning,
    required this.blankWords,
  });
}

class ScriptureDeckEngine {
  static final List<ScriptureCard> scriptures = [
    ScriptureCard(
      id: 1,
      category: "1. 서론 (성경 기록 목적)",
      reference: "요한일서 5장 13절",
      text: "내가 너희에게 이것을 쓰는 것은 너희로 하여금 너희에게 영생이 있음을 알게 하려 함이라",
      meaning: "성경 기록의 목적은 우리에게 영생이 있음을 알려주어 확신을 갖도록 하기 위함",
      blankWords: ["너희에게", "이것을 쓰는 것은", "영생", "알게 하려"],
    ),
    ScriptureCard(
      id: 2,
      category: "2.1 은혜 (Grace)",
      reference: "에베소서 2장 8-9절",
      text:
          "너희는 그 은혜에 의하여 구원을 받았으니 이것은 너희에게서 난 것이 아니요 하나님의 선물이라 행위에서 난 것이 아니니 이는 누구든지 자랑하지 못하게 함이라",
      meaning: "영생은 값없이 주시는 하나님의 선물이며 인간의 행위나 공로로 얻는 것이 아님",
      blankWords: ["은혜", "구원", "하나님의 선물", "행위", "자랑"],
    ),
    ScriptureCard(
      id: 3,
      category: "2.2 인간 (Humanity)",
      reference: "로마서 3장 23절",
      text: "모든 사람이 죄를 범하였으매 하나님의 영광에 이르지 못하더니",
      meaning: "모든 인간은 죄인이며 스스로 하나님의 영광과 기준에 도달할 수 없음",
      blankWords: ["모든 사람", "죄", "하나님의 영광"],
    ),
    ScriptureCard(
      id: 4,
      category: "2.3 하나님 (사랑)",
      reference: "요한일서 4장 8절b",
      text: "하나님은 사랑이심이라",
      meaning: "하나님은 자비로우셔서 우리를 벌하시는 것을 원치 않으심",
      blankWords: ["하나님", "사랑"],
    ),
    ScriptureCard(
      id: 5,
      category: "2.3 하나님 (공의)",
      reference: "출애굽기 34장 7절b",
      text: "벌을 면제하지는 아니하고 보응하리라",
      meaning: "하나님은 의로우시기 때문에 반드시 우리 죄를 벌하셔야만 함",
      blankWords: ["벌", "면제하지", "보응하리라"],
    ),
    ScriptureCard(
      id: 6,
      category: "2.4 예수 그리스도 (Christ)",
      reference: "이사야 53장 6절",
      text:
          "우리는 다 양 같아서 그릇 행하여 각기 제 길로 갔거늘 여호와께서는 우리 모두의 죄악을 그에게 예수 그리스도에게 담당시키셨도다",
      meaning: "우리의 모든 죄를 예수 그리스도께 옮겨 십자가에서 대신 대속하심",
      blankWords: ["양 같아서", "그릇 행하여", "죄악", "담당시키셨도다"],
    ),
    ScriptureCard(
      id: 7,
      category: "2.5 믿음 (Faith)",
      reference: "사도행전 16장 31절",
      text: "주 예수를 믿으라. 그리하면 너와 네 집이 구원을 받으리라",
      meaning: "오직 예수 그리스도만을 전적으로 신뢰함으로 구원을 받음",
      blankWords: ["주 예수", "믿으라", "구원"],
    ),
    ScriptureCard(
      id: 8,
      category: "3. 결신 / 구원의 확신",
      reference: "요한복음 6장 47절",
      text: "진실로 진실로 너희에게 이르노니 믿는 자는 영생을 가졌나니",
      meaning: "예수 그리스도를 믿는 자는 이미 영생을 가졌다는 확실한 약속",
      blankWords: ["진실로", "너희에게", "믿는 자", "영생을 가졌나니"],
    ),
  ];

  static List<ScriptureCard> getAllScriptures() => scriptures;
}
