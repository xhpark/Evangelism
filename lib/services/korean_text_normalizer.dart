class KoreanTextNormalizer {
  /// 실제 추임새만 제거한다.
  /// (2026-08-29: '그', '이', '저', '아', '에', '막'은 대본에 쓰이는 지시어·감탄사·부사라
  ///  간투사 목록에서 제외했다. 예: "아! 그러시군요", "그 은혜에 의하여")
  static final List<String> _fillerWords = [
    '어',
    '음',
    '으',
    '흠',
    '에또',
    '어어',
    '음음',
    '으음',
    '어...',
    '음...',
    '그니까',
    '저기요',
  ];

  /// 한글 수사 → 숫자
  static const Map<String, int> _numeralUnits = {
    '일': 1,
    '이': 2,
    '삼': 3,
    '사': 4,
    '오': 5,
    '육': 6,
    '륙': 6,
    '칠': 7,
    '팔': 8,
    '구': 9,
    '한': 1,
    '두': 2,
    '세': 3,
    '네': 4,
    '다섯': 5,
    '여섯': 6,
    '일곱': 7,
    '여덟': 8,
    '아홉': 9,
    '열': 10,
  };

  /// 숫자로 바꾸면 뜻이 달라지는 단어는 건드리지 않는다.
  static const List<String> _numeralExceptions = ['일절', '일체', '사장', '공장', '과장'];

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

    // 4. 빈출 수사 및 계량 어절 통일 (두 가지 ↔ 2가지, 일 년 ↔ 1년 등)
    text = normalizeNumerals(text);

    // 5. 다중 공백 단일화 및 트림
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return text;
  }

  /// 빈출 수사 및 계량 단위 정규화 (교재 대본 표준 표기로 통일)
  static String normalizeNumerals(String input) {
    String text = input;
    text = text.replaceAll(RegExp(r'2\s*가지'), '두 가지');
    text = text.replaceAll(RegExp(r'3\s*가지'), '세 가지');
    text = text.replaceAll(RegExp(r'4\s*가지'), '네 가지');
    text = text.replaceAll(RegExp(r'5\s*가지'), '다섯 가지');

    text = text.replaceAll(RegExp(r'1\s*째|첫\s*번째'), '첫째');
    text = text.replaceAll(RegExp(r'2\s*째|두\s*번째'), '둘째');
    text = text.replaceAll(RegExp(r'3\s*째|세\s*번째'), '셋째');
    text = text.replaceAll(RegExp(r'4\s*째|네\s*번째'), '넷째');
    text = text.replaceAll(RegExp(r'5\s*째|다섯\s*번째'), '다섯째');

    text = text.replaceAll(RegExp(r'하루\s*3\s*번'), '하루 세 번');
    text = text.replaceAll(RegExp(r'1\s*년'), '일 년');
    text = text.replaceAll(RegExp(r'1000\s*번'), '천 번');
    text = text.replaceAll(RegExp(r'90000\s*번|9\s*만\s*번|구만\s*번'), '9만 번');
    text = text.replaceAll(RegExp(r'구십\s*평생|구십평생'), '90평생');
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
  ///
  /// "이장 팔절" ➔ "2장 8절", "오십삼장" ➔ "53장" 처럼
  /// **어절 전체가 수사 + 장/절인 경우에만** 변환한다.
  /// "사장님은", "일절 관여" 같은 낱말은 그대로 둔다.
  static String normalizeScriptureRef(String input) {
    final words = input.split(RegExp(r'\s+'));

    final converted = words.map((word) {
      if (word.isEmpty) return word;
      if (_numeralExceptions.contains(word)) return word;

      final match = RegExp(r'^([가-힣]+)(장|절)$').firstMatch(word);
      if (match == null) return word;

      final numeralPart = match.group(1)!;
      final unit = match.group(2)!;
      final value = _parseKoreanNumeral(numeralPart);
      if (value == null) return word;

      return '$value$unit';
    }).toList();

    return converted.join(' ');
  }

  /// "이십삼" ➔ 23, "십육" ➔ 16, "오" ➔ 5. 수사로 해석되지 않으면 null.
  static int? _parseKoreanNumeral(String text) {
    if (text.isEmpty) return null;

    // 십 단위 조합 처리 (예: 이십삼, 십육, 삼십)
    final tenIdx = text.indexOf('십');
    if (tenIdx != -1) {
      final beforeTen = text.substring(0, tenIdx);
      final afterTen = text.substring(tenIdx + 1);

      int tens = 1;
      if (beforeTen.isNotEmpty) {
        final t = _numeralUnits[beforeTen];
        if (t == null || t > 9) return null;
        tens = t;
      }

      int ones = 0;
      if (afterTen.isNotEmpty) {
        final o = _numeralUnits[afterTen];
        if (o == null || o > 9) return null;
        ones = o;
      }

      return tens * 10 + ones;
    }

    return _numeralUnits[text];
  }
}
