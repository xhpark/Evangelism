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
      category: "은혜 (Grace)",
      reference: "에베소서 2장 8-9절",
      text: "너희는 그 은혜에 의하여 믿음으로 말미암아 구원을 받았으니 이것은 너희에게서 난 것이 아니요 하나님의 선물이라 행위에서 난 것이 아니니 이는 누구든지 자랑하지 못하게 함이라",
      meaning: "영생은 값없이 주시는 하나님의 선물이며 인간의 행위로 얻는 것이 아님",
      blankWords: ["은혜", "믿음", "선물", "행위", "자랑"],
    ),
    ScriptureCard(
      id: 2,
      category: "은혜 (Grace)",
      reference: "로마서 6장 23절",
      text: "죄의 삯은 사망이요 하나님의 은사는 그리스도 예수 우리 주 안에 있는 영생이니라",
      meaning: "죄의 결과는 사망이나 하나님의 선물은 영생임",
      blankWords: ["죄의 삯", "사망", "은사", "영생"],
    ),
    ScriptureCard(
      id: 3,
      category: "인간 (Humanity)",
      reference: "로마서 3장 23절",
      text: "모든 사람이 죄를 범하였으매 하나님의 영광에 이르지 못하더니",
      meaning: "모든 인간은 죄인이며 하나님의 기준에 도달할 수 없음",
      blankWords: ["모든 사람", "죄", "하나님의 영광"],
    ),
    ScriptureCard(
      id: 4,
      category: "인간 (Humanity)",
      reference: "마태복음 5장 48절",
      text: "그러므로 하늘에 계신 너희 아버지의 온전하심과 같이 너희도 온전하라",
      meaning: "하나님의 구원 표준은 100% 온전함(완전함)임",
      blankWords: ["아버지", "온전하심", "온전하라"],
    ),
    ScriptureCard(
      id: 5,
      category: "하나님 (God)",
      reference: "요한일서 4장 8절b",
      text: "하나님은 사랑이심이라",
      meaning: "하나님은 자비로우셔서 우리를 벌하기를 원치 않으심",
      blankWords: ["하나님", "사랑"],
    ),
    ScriptureCard(
      id: 6,
      category: "하나님 (God)",
      reference: "출애굽기 34장 7절b",
      text: "인자를 천대까지 베풀며 악과 과실과 죄를 용서하리라 그러나 벌을 면제하지는 아니하고",
      meaning: "하나님은 공의로우셔서 죄를 반드시 심판하셔야 함",
      blankWords: ["인자", "용서", "벌", "면제하지"],
    ),
    ScriptureCard(
      id: 7,
      category: "예수 그리스도 (Christ)",
      reference: "요한복음 1장 1절, 14절",
      text: "태초에 말씀이 계시니라 이 말씀이 하나님과 함께 계셨으니 이 말씀은 곧 하나님이시니라... 말씀이 육신이 되어 우리 가운데 거하시매",
      meaning: "예수 그리스도는 무한하신 하나님이시며 참 인간이심",
      blankWords: ["태초", "말씀", "하나님", "육신"],
    ),
    ScriptureCard(
      id: 8,
      category: "예수 그리스도 (Christ)",
      reference: "이사야 53장 6절",
      text: "우리는 다 양 같아서 그릇 행하여 각기 제 길로 갔거늘 여호와께서는 우리 모두의 죄악을 그에게 담당시키셨도다",
      meaning: "우리의 모든 죄를 예수 그리스도께 옮겨 대신 대속하심",
      blankWords: ["양", "죄악", "담당"],
    ),
    ScriptureCard(
      id: 9,
      category: "믿음 (Faith)",
      reference: "사도행전 16장 31절",
      text: "주 예수를 믿으라 그리하면 너와 네 집이 구원을 받으리라",
      meaning: "오직 예수 그리스도만을 전적으로 신뢰함으로 구원받음",
      blankWords: ["주 예수", "믿으라", "구원"],
    ),
    ScriptureCard(
      id: 10,
      category: "구원의 확신 (Assurance)",
      reference: "요한복음 6장 47절",
      text: "진실로 진실로 너희에게 이르노니 믿는 자는 영생을 가졌나니",
      meaning: "예수를 믿는 자에게 즉시 영생이 주어짐",
      blankWords: ["진실로", "믿는 자", "영생"],
    ),
  ];

  static List<ScriptureCard> getAllScriptures() => scriptures;
}
