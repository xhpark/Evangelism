class KoreanTextNormalizer {
  static final List<String> _fillerWords = [
    '어', '음', '저', '그', '아', '에', '막', '음...', '어...', '저...', '그...'
  ];

  static final Map<String, String> _numberMap = {
    '일': '1',
    '이': '2',
    '삼': '3',
    '사': '4',
    '오': '5',
    '육': '6',
    '칠': '7',
    '팔': '8',
    '구': '9',
    '십': '10',
    '한': '1',
    '두': '2',
    '세': '3',
    '네': '4',
    '다섯': '5',
  };

  /// 전체 정규화 파이프라인
  static String normalize(String input) {
    if (input.isEmpty) return '';

    String text = input;

    // 1. 특수문자 및 구두점 제거
    text = text.replaceAll(RegExp(r'[^\w\sㄱ-ㅎ가-힣]'), ' ');

    // 2. 추임새/간투사 제거
    text = filterFillers(text);

    // 3. 한글 숫자/성경 장절 정규화
    text = normalizeScriptureRef(text);

    // 4. 다중 공백 단일화 및 트림
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return text;
  }

  /// 추임새 필터링
  static String filterFillers(String input) {
    final words = input.split(RegExp(r'\s+'));
    final filtered = words.where((w) {
      final clean = w.replaceAll(RegExp(r'[^\wㄱ-ㅎ가-힣]'), '');
      return !_fillerWords.contains(clean);
    }).toList();
    return filtered.join(' ');
  }

  /// 한글 수사 ➔ 아라비아 숫자 및 장/절 통일
  static String normalizeScriptureRef(String input) {
    String text = input;

    // 예: "이장 팔절" ➔ "2장 8절"
    _numberMap.forEach((hangul, digit) {
      text = text.replaceAll('$hangul장', '$digit장');
      text = text.replaceAll('$hangul절', '$digit절');
    });

    // "이십삼절" ➔ "23절", "사십팔절" ➔ "48절"
    text = text.replaceAll('삼장', '3장');
    text = text.replaceAll('이십삼절', '23절');
    text = text.replaceAll('오장', '5장');
    text = text.replaceAll('사십팔절', '48절');
    text = text.replaceAll('삼십사장', '34장');
    text = text.replaceAll('칠절', '7절');
    text = text.replaceAll('오십삼장', '53장');
    text = text.replaceAll('십육장', '16장');
    text = text.replaceAll('삼십일절', '31절');
    text = text.replaceAll('육장', '6장');
    text = text.replaceAll('사십칠절', '47절');

    return text;
  }
}
